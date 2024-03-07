function CompFatigue( SettingsFile )
% Perform a fatigue anaylsis.
%
% For now, it does a rainflow analysis and calculates damage equivalent loads
% for individual times series.  The DELs are not weighted by a probability
% distribution.
%
% Syntax is:  CompFatigue( SettingsFile );
%
% Example:
%     CompFatigue( 'MySettings.mcru' );
%
% See also DelFile, GetRoot, MCrunch, ReadSettings

   global FileInfo Fatigue ProgName RealFmt StrFmt StrFmtL


      % Tell the user we are doing a fatigue analysis.

   fprintf( '\n  Performing fatigue analysis.\n' );


      % Eliminate any selected channels that are constant or determine the number of bins
      % if we are binning the cycles.

   NumFatChan = size( Fatigue.ChanInfo , 2 );
   NumFiles   = size( FileInfo.FileName, 1 );

   if ( NumFiles > 1 )
      DoAgg = true;
   else
      DoAgg = false;
   end % if ( NumFiles > 1 )

   Range  = zeros( 1, NumFatChan );
   Minima = zeros( 1, NumFatChan );
   Maxima = zeros( 1, NumFatChan );

   AllConstant = true;


      % Compute the time elapsed in each file.

   for File=1:NumFiles
      BegTime                = FileInfo.Time(FileInfo.StartLine(File)                          ,FileInfo.TimeChan);
      EndTime                = FileInfo.Time(FileInfo.StartLine(File)+FileInfo.NumLines(File)-1,FileInfo.TimeChan);
      Fatigue.ElapTime(File) = EndTime - BegTime;
   end % for File


      % Calculate the bin probabilities for the wind-speed bins.

   if ( Fatigue.DoLife )


         % Of all the files, what is the largest mean wind speed?

      MaxAver = 0;

      for File=1:NumFiles
         if ( FileInfo.Stats.Means(File,FileInfo.WSChan) > MaxAver )
            MaxAver = FileInfo.Stats.Means(File,FileInfo.WSChan);
         end % if
      end % for File


         % Determine the probability for each wind-speed bin using the Rayleigh distribution.

      NumWSbins      = ceil( ( MaxAver - Fatigue.WSmin )/Fatigue.WSdel );
      Fatigue.WSProb = zeros( NumWSbins, 1 );
%      MPi2Vavg       = -0.25*pi/Fatigue.RayAverWS^2;
      AvSR2byPi      = Fatigue.RayAverWS*sqrt( 2/pi );

      for Bin=1:NumWSbins
         WShi                = Fatigue.WSmin + Bin*Fatigue.WSdel;
         WSlo                = WShi - Fatigue.WSdel;
%         Fatigue.WSProb(Bin) = exp( MPi2Vavg*WSlo^2 ) - exp( MPi2Vavg*WShi^2 );
         Fatigue.WSProb(Bin) = raylcdf( WShi, AvSR2byPi ) - raylcdf( WSlo, AvSR2byPi );
      end % for Bin


         % Compute the total time in each wind-speed bin.

      Fatigue.Time = zeros( NumWSbins, 1 );

      for File=1:NumFiles
         WSbin                  = ceil( ( FileInfo.Stats.Means(File,FileInfo.WSChan) - Fatigue.WSmin )/Fatigue.WSdel );
         Fatigue.Time(WSbin)    = Fatigue.Time(WSbin) + Fatigue.ElapTime(File);
      end % for File

   end % if ( Fatigue.DoLife )


   for Ch=1:NumFatChan

      Chan                          = Fatigue.ChanInfo(Ch).Chan;
      Fatigue.ChanInfo(Ch).ChanName = FileInfo.Names{Chan};

      if ( DoAgg )
         Range (Ch) = FileInfo.Stats.AggRange (Chan);
         Minima(Ch) = FileInfo.Stats.AggMinima(Chan);
         Maxima(Ch) = FileInfo.Stats.AggMaxima(Chan);
      else
         Range (Ch) = FileInfo.Stats.Range (Chan);
         Minima(Ch) = FileInfo.Stats.Minima(Chan);
         Maxima(Ch) = FileInfo.Stats.Maxima(Chan);
      end % if ( DoAgg )

   end % for Ch


      % See if all the channels have constant data.  If so, we are done.

   if ( max( Range ) == 0.0 )
      beep;
      error( '\n  All selected fatigue columns have constant data.  Fatigue calculations skipped.\n' );
   end % if


      % Delete any old information.  Create the Cycles and Bins branches.

   if ( DoAgg )
      Fatigue.Agg.RF(1:NumFatChan) = struct( 'NumCCycles', [], 'Cycles', [], 'Bins', [] );
   end % if ( DoAgg )

   Fatigue.File(NumFiles).RF(NumFatChan) = struct( 'NumCCycles', [], 'Cycles', [], 'Bins', [] );


      % Set the string for the RF period.

 %  if ( Fatigue.BinCycles )
      Fatigue.RFPerStr = RFPerUnits( Fatigue.RF_Per );
 %  end % if


      % Process the aggregate (if more than one) and all the files.

   if ( DoAgg )
      FirstFile = 0;
   else
      FirstFile = 1;
   end % if ( DoAgg )

   for File=FirstFile:NumFiles


         % If we are binning cycles, determine the time scale factor.
         % If the RF period is 0, just count cycles.
         % We are assuming that the data has a constant time step and
         % that the first file has at least to time steps.

      if ( File == 0 )
         fprintf( '    Performing fatigue analysis of aggregate data:\n' );
         NumLines = size( FileInfo.Time, 1 ) - 1;
      else
         fprintf( '    Performing fatigue analysis for "%s":\n', FileInfo.FileName{File} );
         NumLines = FileInfo.NumLines(File) - 1;
      end % if ( File == 0 )

      if ( Fatigue.BinCycles )

         if ( Fatigue.RF_Per == 0 )
            TimeFact = 1;
         else
            if ( File == 0 )
               TimeFact = Fatigue.RF_Per/sum( Fatigue.ElapTime );
            else
               TimeFact = Fatigue.RF_Per/Fatigue.ElapTime(File);
            end % if
         end % if ( Fatigue.RF_Per == 0 )

      else

         if ( File == 0 )
            TimeFact = 1.0/sum( Fatigue.ElapTime );
         else
            TimeFact = 1.0/Fatigue.ElapTime(File);
         end % if

      end % if


         % Loop through the channels.  Cycle count, then bin the cycles if requested.

      for Ch=1:size( Fatigue.ChanInfo, 2 )

         Chan = Fatigue.ChanInfo(Ch).Chan;

         fprintf( '      %s:', FileInfo.Names{Chan} )

%TODO: Deal with multiple slopes.
         if ( File == 0 )
            [ Fatigue.Agg.RF(Ch).Cycles, Fatigue.Agg.RF(Ch).DEL, Fatigue.Agg.RF(Ch).Bins ] = Rainflow( File, Ch, Range(Ch), TimeFact, Fatigue.ChanInfo(Ch).SNslopes );
         else
            [ Fatigue.File(File).RF(Ch).Cycles, Fatigue.File(File).RF(Ch).DEL, Fatigue.File(File).RF(Ch).Bins ] = Rainflow( File, Ch, Range(Ch), TimeFact, Fatigue.ChanInfo(Ch).SNslopes );
         end % if ( File == 0 )


            % Accumulate cycles if requested.

         if ( Fatigue.CumFatigue )

            if ( File == 0 )

               NumCycles  = size( Fatigue.Agg.RF(Ch).Cycles, 1 );

               SortCycles = sortrows( [ Fatigue.Agg.RF(Ch).Cycles(:,3), Fatigue.Agg.RF(Ch).Cycles(:,4) ], -1 );
               Fatigue.Agg.RF(Ch).CumCycles = zeros( 2*NumCycles, 2 );

               Fatigue.Agg.RF(Ch).CumCycles(1:2,1) = [ SortCycles(1,1); SortCycles(1,1) ];
               Fatigue.Agg.RF(Ch).CumCycles(2,2)   = SortCycles(1,2);

               for Cyc=2:NumCycles
                  Fatigue.Agg.RF(Ch).CumCycles(2*Cyc-1:2*Cyc,1) = [ SortCycles(Cyc,1); SortCycles(Cyc,1) ];
                  Fatigue.Agg.RF(Ch).CumCycles(2*Cyc-1,2) = Fatigue.Agg.RF(Ch).CumCycles(2*Cyc-2,2);
                  Fatigue.Agg.RF(Ch).CumCycles(2*Cyc  ,2) = Fatigue.Agg.RF(Ch).CumCycles(2*Cyc-1,2) + SortCycles(Cyc,2);
               end % for Cyc

            else

               NumCycles  = size( Fatigue.File(File).RF(Ch).Cycles, 1 );

               SortCycles = sortrows( [ Fatigue.File(File).RF(Ch).Cycles(:,3), Fatigue.File(File).RF(Ch).Cycles(:,4) ], -1 );
               Fatigue.File(File).RF(Ch).CumCycles = zeros( 2*NumCycles, 2 );

               Fatigue.File(File).RF(Ch).CumCycles(1:2,1) = [ SortCycles(1,1); SortCycles(1,1) ];
               Fatigue.File(File).RF(Ch).CumCycles(2,2)   = SortCycles(1,2);

               for Cyc=2:NumCycles
                  Fatigue.File(File).RF(Ch).CumCycles(2*Cyc-1:2*Cyc,1) = [ SortCycles(Cyc,1); SortCycles(Cyc,1) ];
                  Fatigue.File(File).RF(Ch).CumCycles(2*Cyc-1,2) = Fatigue.File(File).RF(Ch).CumCycles(2*Cyc-2,2);
                  Fatigue.File(File).RF(Ch).CumCycles(2*Cyc  ,2) = Fatigue.File(File).RF(Ch).CumCycles(2*Cyc-1,2) + SortCycles(Cyc,2);
               end % for Cyc

            end % if ( File == 0 )

         end % if

      end % for Ch

   end % for File


      % If requested, do the lifetime calculations.

   if ( Fatigue.DoLife && ( File > 0 ) )
      CompLife( File, Ch );
   end % if


         % When plotting range/mean bins, search for vectors of all zeros from both sides of
         % the Bins matrix and eliminate them.  Eliminate the elements of MBinVals too.

   if ( Fatigue.PltRngMean )

      for Ch=1:size( Fatigue.ChanInfo, 2 )

         for MInd=1:Fatigue.File.RF(Ch).NumMBins
            if ( std( Fatigue.File.RF(Ch).Bins(:,MInd) ) > 0.0 );
               if ( MInd > 1 )
                  Fatigue.File.RF(Ch).Bins(:,1:MInd-1) = [];
                  Fatigue.File.RF(Ch).MBinVals(:,1:MInd-1) = [];
                  Fatigue.File.RF(Ch).NumMBins = Fatigue.File.RF(Ch).NumMBins - MInd + 1;
               end % if
               break
            end % if
         end % for MInd

         for MInd=Fatigue.File.RF(Ch).NumMBins:-1:1
            if ( std( Fatigue.File.RF(Ch).Bins(:,MInd) ) > 0.0 );
               if ( MInd < Fatigue.File.RF(Ch).NumMBins )
                  Fatigue.File.RF(Ch).Bins(:,MInd+1:Fatigue.File.RF(Ch).NumMBins) = [];
                  Fatigue.File.RF(Ch).MBinVals(MInd+1:Fatigue.File.RF(Ch).NumMBins) = [];
                  Fatigue.File.RF(Ch).NumMBins = MInd;
               end % if
               break
            end % if
         end % for MInd

      end % for Ch
   end % if


      % Write out results.

   if ( Fatigue.DoSimpDELs && Fatigue.TblDELs )

      if ( Fatigue.WrDELsTxt )
       fprintf( '    Damage-equivalent-load tables.\n' );
       WrDELsTxt;
      end % if

      if ( Fatigue.WrDELsXLS )
       WrDELsXLS;
      end % if

      if ( Fatigue.TblDELs )
       fprintf( '    Damage-equivalent-load tables.\n' );
       GenTblDELhtml;
      end % if

   end % if

   if ( Fatigue.WrRFTxt )
      WrRFTxt;
   end % if

   if ( Fatigue.WrRFXLS )
      WrRFXLS;
   end % if

   fprintf( '  Done.\n' );

   return
%=======================================================================
   function CompLife( File, Ch )
   % Compute the life.

      Fatigue.Damage = zeros( NumFatChan, 1 );

      for File=1:NumFiles

         WSbin = ceil( ( FileInfo.Stats.Means(File,FileInfo.WSChan) - Fatigue.WSmin )/Fatigue.WSdel );

         for Ch=1:NumFatChan
            for Bin=1:Fatigue.File(File).RF(Ch).NumRBins
               Cycles2Fail        = ( ( Fatigue.ChanInfo(Ch).LUlt - Fatigue.ChanInfo(Ch).LMF )/( 0.5*Fatigue.File(File).RF(Ch).RBinVals(Bin) ) )^Fatigue.ChanInfo(Ch).SNslopes(1);
               LifeCycles         = Fatigue.WSProb(WSbin)*Fatigue.File(File).RF(Ch).Bins(Bin)*Fatigue.ElapTime(File)/Fatigue.Time(WSbin);
               Fatigue.Damage(Ch) = Fatigue.Damage(Ch) + LifeCycles/Cycles2Fail;
            end % for Bin
         end % for Ch

      end % for File


         % Write out the results.

      if ( Fatigue.WrLifeTxt )
         WrLifeTxt;
      end % if

      if ( Fatigue.WrLifeXLS )
         WrLifeXLS;
      end % if

      return
%=======================================================================
      function WrLifeTxt
      % Write lifetime predictions to a text file.

      global AggRoot


         % Set up the header.

      DateTime = clock;

      Head = sprintf( 'These fatigue-life estimates were generated by %s on %s at %02d:%02d:%02d.', ProgName, date, uint8( DateTime(4:6) ) );

      fprintf( '    Writing fatigue-life estimates to:\n' );


         % Open output file.  Write header.

      LifeFile = [ AggRoot, '.life' ];

      fprintf( '      %s\n', LifeFile );

      UnL = fopen( LifeFile, 'wt' );

      if ( UnL < 0 )
         beep
         error( sprintf( '  Could not open "%s" for writing.', LifeFile ) );
      end

      fprintf( UnL, '\n%s\n', Head );


         % Generate the table.

      MaxNameLen = max( 7, size( char( FileInfo.Names{[Fatigue.ChanInfo(:).Chan ]} ), 2 ) );

      if ( FileInfo.HaveUnits )

         MaxUnitsLen = max( 5, size( char( FileInfo.Units{[Fatigue.ChanInfo(:).Chan]} ), 2 ) );
         StrFmt      = [ '%-', sprintf( '%d', MaxNameLen ), 's %-', sprintf( '%d', MaxUnitsLen ), 's' ];

         fprintf( UnL, [ '\n', StrFmt, '   Lifetime Damage\n', StrFmt, '   ---------------\n'], 'Channel', 'Units', '-------', '-----' );

         for Ch=1:NumFatChan
            fprintf( UnL, [ StrFmt, '  ', RealFmt, '\n' ], FileInfo.Names{Fatigue.ChanInfo(Ch).Chan}, FileInfo.Units{Fatigue.ChanInfo(Ch).Chan}, Fatigue.Damage(Ch) );
         end % for Ch

      else

         StrFmt = [ '%-', sprintf( '%d', MaxNameLen ), 's' ];

         fprintf( UnL, [ '\n', StrFmt, '   Lifetime Damage\n', StrFmt, '   ---------------\n'], 'Channel', '-------' );

         for Ch=1:NumFatChan
            fprintf( UnL, [ StrFmt, '  ', RealFmt, '\n' ], FileInfo.Names{Fatigue.ChanInfo(Ch).Chan}, Fatigue.Damage(Ch) );
         end % for Ch

      end % if ( FileInfo.HaveUnits )

      fprintf( UnL, '\n' );


         % Close the file.

      fclose( UnL );


      end % function WrLifeTxt
%=======================================================================
      function WrLifeXLS
      % Write lifetime predictions to an Excel file.

      global AggRoot


         % Set up the header.

      DateTime = clock;

      Head = sprintf( 'These fatigue-life estimates were generated by %s on %s at %02d:%02d:%02d.', ProgName, date, uint8( DateTime(4:6) ) );

      fprintf( '    Writing fatigue-life estimates to:\n' );


         % Set up the name of the Excel file.  Delete the file if it already exists

      XLSfile = [ AggRoot, '_life.xlsx' ];

      fprintf( '      %s\n', XLSfile );

      DelFile( XLSfile );


         % Turn off warnings regarding adding sheets to the workbook.

      warning off MATLAB:xlswrite:AddSheet


         % Get the date and time.

      DateTime = clock;


         % Generate the table.

      if ( FileInfo.HaveUnits )

         SheetInfo      = cell( NumFatChan+3, 3 );
         SheetInfo{1,1} = sprintf( 'These fatigue-life estimates were generated by %s on %s at %02d:%02d:%02d.', ProgName, date, uint8( DateTime(4:6) ) );
         SheetInfo{3,1} = 'Channel';
         SheetInfo{3,2} = 'Units';
         SheetInfo{3,3} = 'Lifetime Damage';

         for Ch=1:NumFatChan
            SheetInfo{Ch+3,1} = sprintf( '%s'   , FileInfo.Names{Fatigue.ChanInfo(Ch).Chan} );
            SheetInfo{Ch+3,2} = sprintf( '%s'   , FileInfo.Units{Fatigue.ChanInfo(Ch).Chan} );
            SheetInfo{Ch+3,3} = sprintf( RealFmt, Fatigue.Damage(Ch) );
         end % for Ch

      else

         SheetInfo      = cell( NumFatChan+3, 2 );
         SheetInfo{1,1} = sprintf( 'These fatigue-life estimates were generated by %s on %s at %02d:%02d:%02d.', ProgName, date, uint8( DateTime(4:6) ) );
         SheetInfo{3,1} = 'Channel';
         SheetInfo{3,2} = 'Lifetime Damage';

         for Ch=1:NumFatChan
            SheetInfo{Ch+3,1} = sprintf( '%s'   , FileInfo.Names{Fatigue.ChanInfo(Ch).Chan} );
            SheetInfo{Ch+3,2} = sprintf( RealFmt, Fatigue.Damage(Ch) );
         end % for Ch

      end % if ( FileInfo.HaveUnits )


         % Create the workbook.

      xlswrite( XLSfile, SheetInfo, 'Fatigue Life', 'A2' );


         % Delete the blank sheet, "Sheet1".

      DelSheet1( XLSfile );


      end % function WrLifeXLS
%=======================================================================
   end % function CompLife
%=======================================================================
   function GenTblDELhtml
   % Generate a table of damage-equivalent loads.  Table is in HTML format.


         % Open the HTML file for writing.
         % Add the header information.

      HTMLfile = [ GetRoot( SettingsFile ), '_DEL.html' ];
      UnH = fopen( HTMLfile, 'wt' );

      if ( UnH < 0 )
         beep
         error( sprintf( '  Could not open "%s" for writing.', HTMLfile ) );
      end

      fprintf( UnH, '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">\n' );
      fprintf( UnH, '<html>\n' );
      fprintf( UnH, '<head><title>Table of Damage-Equivalent Loads</title></head>\n' );
      fprintf( UnH, '<body>\n' );
      fprintf( UnH, '<center><h2><font color="navy">Damage-Equivalent Loads</font></h2>\n' );


         % Set up a table to display the DELs.

      NumFiles = size( FileInfo.FileName, 1 );

      fprintf( UnH, '<table border="0" cellpadding="1" width="100%%">\n' );


         % Generate the header of the table.

      if ( FileInfo.HaveUnits )
         fprintf( UnH, '<tr><th align="left">Channel</th><th align="center">Units</th><th align="center">S/N Slope</th>' );
      else
         fprintf( UnH, '<tr><th align="left">Channel</th><th align="center">S/N Slope</th>' );
      end % if

      if ( NumFiles == 1 )

         fprintf( UnH, '<th align="right">DEL</th></tr>\n' );

      else

         fprintf( UnH, '<th align="right"><font color="navy">Aggregate</font></th>' );

         NumStr = sprintf( '%d', ceil( log10( NumFiles ) ) );

         for File=1:NumFiles
            fprintf( UnH, [ '<th align="right">File%', NumStr, 'd</th>' ], File );
         end % for File

         fprintf( UnH, '</tr>\n' );

      end % if


         % Generate the body of the table.

      for Ch=1:size( Fatigue.ChanInfo, 2 )

%TODO: Deal with multiple slopes.
         if ( FileInfo.HaveUnits )
            fprintf( UnH, '<tr><td align="left">%-10s</td><td align="center">%-10s</td><td align="center">%d</td>', Fatigue.ChanInfo(Ch).ChanName, FileInfo.Units{Fatigue.ChanInfo(Ch).Chan}, Fatigue.ChanInfo(Ch).SNslopes );
         else
            fprintf( UnH, '<tr><td align="left">%-10s</td><td align="center">%d</td>', Fatigue.ChanInfo(Ch).ChanName, Fatigue.ChanInfo(Ch).SNslopes );
         end % if

         if ( NumFiles == 1 )

            fprintf( UnH, [ '<td align="right">', RealFmt, '</td></tr>\n' ], Fatigue.File(1).RF(Ch).DEL );

         else

            fprintf( UnH, [ '<td align="right"><font color="navy">', RealFmt, '</font></td>' ], Fatigue.Agg.RF(Ch).DEL );

            for File=1:NumFiles
               fprintf( UnH, [ '<td align="right">', RealFmt, '</td>' ], Fatigue.File(File).RF(Ch).DEL );
            end % for File

            fprintf( UnH, '</tr>\n' );

         end % if

      end % for


         % End the table.

      fprintf( UnH, '</table>\n' );


         % Create a new table of file names.

      fprintf( UnH, '<br><table border="0" cellpadding="1" width="100%%">\n' );

      if ( NumFiles == 1 )
         fprintf( UnH, '<tr><td>&nbsp;</td><td align="center">File: %s</td></tr>\n', FileInfo.FileName{1} );
      else
         for File=1:NumFiles
            fprintf( UnH, [ '<tr><td>&nbsp;</td><td align="left">File%', NumStr, 'd: %s</td></tr>\n' ], File, FileInfo.FileName{File} );
         end % for
      end % if


         % End the table.

      fprintf( UnH, '</table>\n' );


         % Close the HTML file and display it on screen.

      fclose( UnH );

      web( HTMLfile, '-new' );           % Uses the MatLab web browser.
  %    web( HTMLfile, '-browser' );        % Uses the computer's default web browser.

      return

   end % function GenTblDELhtml
%=======================================================================
%TODO: Deal with multiple slopes.
   function [ Cycles, DEL, Bins ] = Rainflow( File, Ch, Range, TimeFact, SNslopes )
   % Finds rainflow cycles in the time series.  Optionally bins the cycles.
   %
   % Cycles(1) = Cycle range for variable means.
   % Cycles(2) = Cycle means.
   % Cycles(3) = Cycle range for fixed means.
   % Cycles(4) = Effective cycle weight.  Use one for full cycles, use UCMult for unclosed cycles.


         % What data channel are we analyzing?

      Chan = Fatigue.ChanInfo(Ch).Chan;


         % Copy the time series for this channel into a temporary array.

      if ( File == 0 )
         TSlen   = FileInfo.TotLines;
         TimeSer = FileInfo.Time(:,Chan);
      else
         TSlen   = FileInfo.NumLines(File);
         TimeSer = FileInfo.Time(FileInfo.StartLine(File):FileInfo.StartLine(File)+TSlen-1,Chan);
      end % if ( File == 0 )


         % Identify peaks and troughs in the time series.  The first and last points are considered peaks or troughs.
         % Sometimes the peaks can be flat for a while, so we have to deal with that nasty situation.

      fprintf( '  Identifying peaks.' );

      [ Peaks, NumPeaks ] = GetPeaks( TimeSer );


         % See if we have at least three points in the Peaks array.

      if ( NumPeaks < 3 )

         if ( File == 0 )
            fprintf( '\n        WARNING: This channel has only %d peaks in the aggregate of all files, so rainflow analysis is not possible.\n\n', NumPeaks );
         else
            fprintf( '\n        WARNING: This channel has only %d peaks in file #%d, so rainflow analysis is not possible.\n\n', NumPeaks, File );
         end % if

         Cycles    = [];
         Bins      = [];
         NumCycles = 0;

         return

      end % if ( NumPeaks < 3 )


         % Optionally use the racetrack filter to eliminate the small cycles.

      if ( Fatigue.FiltRatio > 0 )
         fprintf( '  Applying racetrack filter.' );
         Peaks    = RTfilt( Peaks, Fatigue.FiltRatio*Range );
         NumPeaks = size( Peaks, 1 );
      end % if ( Fatigue.FiltRatio > 0 )


         % See if we still have at least three points in the Peaks array after we've filtered it.

      if ( NumPeaks < 3 )

         beep;

         if ( Fatigue.FiltRatio > 0 )
            fprintf( '\n        WARNING: After applying the racetrack filter and reordering the series, %s has\n', FileInfo.Names{Chan}, NumPeaks );
            fprintf( '                 only %d peaks, so rainflow analysis is not possible for it.\n\n' );
         else
            fprintf( '\n        WARNING: After reordering the series, %s has only %d peaks,\n', FileInfo.Names{Chan}, NumPeaks );
            fprintf( '                 so rainflow analysis is not possible for it.\n\n' );
         end % if ( Fatigue.FiltRatio > 0 )


         Cycles    = [];
         Bins      = [];
         NumCycles = 0;

         return

      end % if ( NumPeaks < 3 )


         % Identify the closed and unclosed cycles.  All cycle ranges, means, and weights are returned in the Cycles array.

      fprintf( '  Finding cycles.' );

      Cycles = GenCycles( Peaks, Fatigue.UCMult, Fatigue.ChanInfo(Ch).LUlt, abs( Fatigue.ChanInfo(Ch).LMF ) );


         % Compute the simple, damage-equivalent loads.

%TODO: Deal with multiple slopes.
      DEL = ( TimeFact*sum( Cycles(:,4).*( Cycles(:,3).^SNslopes ) ) )^( 1/SNslopes );


         % If requested, bin the cycles.

      if ( Fatigue.BinCycles )


         fprintf( '  Binning cycles.' );


            % Set up the bins.

               % If we are binning means, bin the variable-mean cycle ranges (col=1).  If not, bin the
               % fixed-mean cycle ranges (col=3).

               % Do this only on the first pass for this channel.

               % NOTE: In the future, we may ask the user what fraction of the bin
               % width should be the reported value.  To be conservative, we should
               % report the most-positive end of the bin.

         if ( File == 0 )

            if ( Fatigue.BinMeans )

               MeanBinMin = Fatigue.ChanInfo(Ch).BinWidth*floor( min( Cycles(:,2) )/Fatigue.ChanInfo(Ch).BinWidth );
               MeanBinMax = Fatigue.ChanInfo(Ch).BinWidth* ceil( max( Cycles(:,2) )/Fatigue.ChanInfo(Ch).BinWidth );

               Fatigue.Agg.RF(Ch).MBinVals = MeanBinMin:Fatigue.ChanInfo(Ch).BinWidth:MeanBinMax-Fatigue.ChanInfo(Ch).BinWidth;
               Fatigue.Agg.RF(Ch).NumMBins = ( MeanBinMax - MeanBinMin )/Fatigue.ChanInfo(Ch).BinWidth;
               Fatigue.Agg.RF(Ch).NumRBins = ceil( Range/Fatigue.ChanInfo(Ch).BinWidth );

               MBinVals = Fatigue.Agg.RF(Ch).MBinVals;

            else

               Fatigue.Agg.RF(Ch).NumMBins = 1;
               Fatigue.Agg.RF(Ch).NumRBins = ceil( max( Cycles(:,3) )/Fatigue.ChanInfo(Ch).BinWidth );

            end % if

            NumRBins = Fatigue.Agg.RF(Ch).NumRBins;
            NumMBins = Fatigue.Agg.RF(Ch).NumMBins;

            Fatigue.Agg.RF(Ch).RBinVals = ( (1:NumRBins) - 0.5 )*Fatigue.ChanInfo(Ch).BinWidth;

         else

            if ( Fatigue.BinMeans )

               MeanBinMin = Fatigue.ChanInfo(Ch).BinWidth*floor( min( Cycles(:,2) )/Fatigue.ChanInfo(Ch).BinWidth );
               MeanBinMax = Fatigue.ChanInfo(Ch).BinWidth* ceil( max( Cycles(:,2) )/Fatigue.ChanInfo(Ch).BinWidth );

               Fatigue.File(File).RF(Ch).MBinVals = MeanBinMin:Fatigue.ChanInfo(Ch).BinWidth:MeanBinMax-Fatigue.ChanInfo(Ch).BinWidth;
               Fatigue.File(File).RF(Ch).NumMBins = ( MeanBinMax - MeanBinMin )/Fatigue.ChanInfo(Ch).BinWidth;
               Fatigue.File(File).RF(Ch).NumRBins = ceil( Range/Fatigue.ChanInfo(Ch).BinWidth );

               MBinVals = Fatigue.File(File).RF(Ch).MBinVals;

            else

               Fatigue.File(File).RF(Ch).NumMBins = 1;
               Fatigue.File(File).RF(Ch).NumRBins = ceil( max( Cycles(:,3) )/Fatigue.ChanInfo(Ch).BinWidth );

            end % if

            NumRBins = Fatigue.File(File).RF(Ch).NumRBins;
            NumMBins = Fatigue.File(File).RF(Ch).NumMBins;

            Fatigue.File(File).RF(Ch).RBinVals = ( (1:NumRBins) - 0.5 )*Fatigue.ChanInfo(Ch).BinWidth;

         end % if


            %Initialize the array.

         Bins = zeros( NumRBins, NumMBins );


            % Bin the cycles.

         for Cyc=1:size( Cycles, 1 );

            if ( Fatigue.BinMeans )
               RInd = ceil( Cycles(Cyc,1)/Fatigue.ChanInfo(Ch).BinWidth );
               MInd = max( 1, ceil( ( Cycles(Cyc,2) - MBinVals(1) )/Fatigue.ChanInfo(Ch).BinWidth ) );
            else
               RInd = ceil( Cycles(Cyc,3)/Fatigue.ChanInfo(Ch).BinWidth );
               MInd = 1;
            end % if ( Fatigue.BinMeans )


               % Increment the bin count by the time-factored cycle weight.

%NOTE: Should we just count cycles instead of normalizing with TimeFact?
            Bins(RInd,MInd) = Bins(RInd,MInd) + TimeFact*Cycles(Cyc,4);

         end % for Cyc


            % When doing 2-D binning, let's report the mean bin values as the center of the bins instead of the left edge.

         if ( Fatigue.BinMeans )
            if ( File == 0 )
               Fatigue.Agg.RF(Ch).MBinVals = Fatigue.Agg.RF(Ch).MBinVals + 0.5*Fatigue.ChanInfo(Ch).BinWidth;
            else
               Fatigue.File(File).RF(Ch).MBinVals = Fatigue.File(File).RF(Ch).MBinVals + 0.5*Fatigue.ChanInfo(Ch).BinWidth;
            end % if
         end % if

      else

         Bins = [];

      end % if ( Fatigue.BinCycles )

      fprintf( '\n' );

      return
%=======================================================================
      function Cycles = GenCycles( Peaks, UCMult, LUlt, LMF )
      % Generate rainflow cycles.

      % Algorithm obtained from:

      %     Ariduru, Seçil (2004).  "Fatigue Life Calculation by Rainflow Cycle Counting Method."
      %     M.S. Thesis.  Ankara, Turkey: Middle East Technical University.

      % The example used in Section 3.2 of the thesis was used to debug this routine.
      % This routine also gives the exact same answers as Crunch.



            % Process the peaks and valleys.

         NumPeaks    = size( Peaks, 1 );
         RemainPeaks = zeros( NumPeaks, 1 );
         Ind         = 0;
         LenUC       = 0;
         NumCycles   = 0;
         Cycles      = zeros( int32( size( Peaks, 1 )/2 - 0.5 ), 4 );
         LFMargin    = LUlt - LMF;

         while ( true )


            if ( Ind < NumPeaks )

               Ind = Ind + 1;

               if ( Ind > NumPeaks ), break, end

               LenUC              = LenUC + 1;
               RemainPeaks(LenUC) = Peaks(Ind);

            end % if ( Ind < NumPeaks )


               % Make sure we have at least three peaks in the RemainPeaksing array.

            while ( LenUC < 3 )

               Ind = Ind + 1;

               if ( Ind > NumPeaks ), break, end

               LenUC              = LenUC + 1;
               RemainPeaks(LenUC) = Peaks(Ind);

            end % while ( LenUC < 3 )


               % Compute the newest and oldest active ranges.

            OldRange = abs( RemainPeaks(LenUC-1) - RemainPeaks(LenUC-2) );
            NewRange = abs( RemainPeaks(LenUC  ) - RemainPeaks(LenUC-1) );


               % If the new range is as large as the oldest active range, we found a cycle.
               % If LenUC is 3, it's a half cycle.  Add it to the list of cycles.

            while ( NewRange >= OldRange )

               NumCycles = NumCycles + 1;

               Cycles(NumCycles,1) = OldRange;
               Cycles(NumCycles,2) = 0.5*( RemainPeaks(LenUC-1) + RemainPeaks(LenUC-2) );
               Cycles(NumCycles,3) = Cycles(NumCycles,1)*LFMargin/( LUlt - abs( Cycles(NumCycles,2) ) );

               if ( LenUC > 3 )
                  Cycles(NumCycles,4)              = 1.0;
                  RemainPeaks((LenUC-2):(LenUC-1)) = [];
                  LenUC                            = LenUC - 2;
               else
                  Cycles(NumCycles,4)    = UCMult;
                  RemainPeaks((LenUC-2)) = [];
                  LenUC                  = LenUC - 1;
               end % if ( LenUC > 3 )

               if ( LenUC >= 3 )
                  OldRange = abs( RemainPeaks(LenUC-1) - RemainPeaks(LenUC-2) );
                  NewRange = abs( RemainPeaks(LenUC  ) - RemainPeaks(LenUC-1) );
               else
                  NewRange = -1;
               end % if ( LenUC >= 3 )

            end % while ( NewRange >= OldRange )

            if ( Ind == NumPeaks ), break, end

         end % while


            % Add the unclosed cycles to the end of the Cycles matrix if the weight is not zero.

         if ( ( LenUC > 1 ) && ( UCMult > 0 ) )

            for Cyc=1:LenUC-1
               Cycles(NumCycles+Cyc,1) = abs ( RemainPeaks(Cyc) - RemainPeaks(Cyc+1) );
               Cycles(NumCycles+Cyc,2) = 0.5*( RemainPeaks(Cyc) + RemainPeaks(Cyc+1) );
               Cycles(NumCycles+Cyc,3) = Cycles(NumCycles+Cyc,1)*LFMargin/( LUlt - abs( Cycles(NumCycles+Cyc,2) ) );
               Cycles(NumCycles+Cyc,4) = UCMult;
            end % for Cyc

         else

            LenUC = 1;

         end % if ( ( LenUC > 1 ) && ( UCMult > 0 ) )


            % Truncate the unused portion of the array.

         TotCycles = NumCycles + LenUC - 1;
         Cycles    = Cycles(1:TotCycles,:);


      end % function Cycles = GenCycles( Peaks, UCMult )
%=======================================================================
      function [ Peaks, NumPeaks ] = GetPeaks( TimeSer )
      % Identify peaks and troughs in the time series.  The first and last points are considered peaks or troughs.
      % Sometimes the peaks can be flat for a while, so we have to deal with that nasty situation.

         Peaks    = TimeSer;
         NumPeaks = 1;
         LastDiff = 1;
         TSlen    = size( TimeSer, 1 );

         for Pt=2:(TSlen-1)

            if ( TimeSer(Pt) == TimeSer(Pt+1) )                                                               % Is slope zero?  Don't update LastDiff is so.
               continue;
            elseif ( ( sign( TimeSer(Pt) - TimeSer(LastDiff) ) + sign( TimeSer(Pt+1) - TimeSer(Pt) ) ) ==  0 )    % Did slope change sign?
               NumPeaks        = NumPeaks + 1;
               Peaks(NumPeaks) = TimeSer(Pt);
            end % if

            LastDiff = Pt;

         end % for Pt


            % Add the last point of the time series to the list of peaks.

         Peaks    = [ Peaks(1:NumPeaks); TimeSer(TSlen) ];
         NumPeaks = NumPeaks + 1;

      end % function [ Peaks, NumPeaks ] = GetPeaks( TimeSer )
%=======================================================================
      function FiltPeaks = RTfilt( Peaks, Thresh )
      % Use the racetrack-filter algorithm to eliminate small cycles from the list of peaks .


            % Initialize the algorithm.

         NumPeaks  = size (    Peaks, 1 );
         FiltPeaks = zeros( NumPeaks, 1 );

         S1 = Peaks(1);
         S2 = Peaks(2);

         Ind     = 2;
         NumKept = 0;

         while ( Ind < NumPeaks )

            Ind = Ind + 1;
            S3  = Peaks(Ind);


               % Calculate the absolute difference between data points.

            Diff12 = abs( S1 - S2 );
            Diff23 = abs( S2 - S3 );
            Diff31 = abs( S3 - S1 );


               % Must find the greatest difference.  If difference is greater then the threshold
               % value, continue with the algorithm; otherwise go back and get another data point.

            if ( Diff12 < Thresh )


                  % See if Diff23 is greatest.

               if ( ( Diff23 >= Diff12 ) && ( Diff23 >= Diff31 ) )

      	         S1 = S2;
      	         S2 = S3;

      	         if ( Diff23 >= Thresh ), break, end                % Jump out of this while loop.


                  % See if Diff31 is greatest.

               elseif ( ( Diff31 >= Diff12 ) && ( Diff31 >= Diff23 ) )

      	         S2 = S3;

      	         if ( Diff31 >= Thresh ), break, end                % Jump out of this while loop.

               end% if

            else

               Ind = Ind - 1;                                        % We don't really want to get another data point just yet, so trick it.

               break                                                 % Jump out of this while loop.

            end % if ( Diff12 < Thresh )

         end % while ( Ind < NumPeaks )


            % If Diff32 is greater then the threshold, write s1 to output file
            % and move s1, s2, and s3 forward in the data file by one.
            % If Diff32 is less than the threshold, points must be discarded.

         while ( Ind < NumPeaks )

            Ind = Ind + 1;
            S3  = Peaks(Ind);

            Diff12 = abs( S1 - S2 );
            Diff23 = abs( S2 - S3 );

            if ( Diff23 >= Thresh )

               NumKept = NumKept + 1;

               FiltPeaks(NumKept) = S1;

               S1 = S2;
               S2 = S3;

            else

               Ind = Ind + 1;

               if ( Ind > NumPeaks ), break, end                     % Jump out of this while loop.

               S3 = Peaks(Ind);

               if ( abs( S1 - S3 ) > Diff12 ), S2 = S3; end

            end % if ( Diff23 >= Thresh )

         end % while  ( Ind < NumPeaks )

         FiltPeaks(NumKept+1) = S1;
         FiltPeaks(NumKept+2) = S2;


            % Eliminate the unused elements.

         FiltPeaks(NumKept+3:NumPeaks) = [];

      end % function FiltPeaks = RTfilt( Peaks, Thresh )
%=======================================================================
   end % function [ Cycles, DEL, Bins ] = Rainflow( File, Ch, Range, TimeFact, SNslopes )
%=======================================================================
   function RFPerStr = RFPerUnits( RF_Per )
   % Determine the units string for the rainflow period.


      if ( RF_Per == 1.0 )

         RFPerStr = 'Cycles per Second';

%      elseif ( RF_Per < 60.0 )
%
%         RFPerStr = sprintf( 'Cycles per %g Seconds', RF_Per );
%
      elseif ( mod( RF_Per, 31536000.0 ) == 0.0 )

         if ( RF_Per == 31536000.0 )
            RFPerStr = 'Cycles per Year';
         else
            RFPerStr = sprintf( 'Cycles per %g Years', RF_Per/31536000.0 );
         end % if

      elseif ( mod( RF_Per, 86400.0 ) == 0.0 )

         if ( RF_Per == 86400.0 )
            RFPerStr = 'Cycles per Day';
         else
            RFPerStr = sprintf( 'Cycles per %g Days', RF_Per/86400.0 );
         end % if

      elseif ( mod( RF_Per, 3600.0 ) == 0.0 )

         if ( RF_Per == 3600.0 )
            RFPerStr = 'Cycles per Hour';
         else
            RFPerStr = sprintf( 'Cycles per %g Hours', RF_Per/3600.0 );
         end % if

      elseif ( mod( RF_Per, 60.0 ) == 0.0 )

         if ( RF_Per == 60.0 )
            RFPerStr = 'Cycles per Minute';
         else
            RFPerStr = sprintf( 'Cycles per %g Minutes', RF_Per/60.0 );
         end % if

      else

         RFPerStr = sprintf( 'Cycles per %g Seconds', RF_Per );

      end % if

   end % function RFPerStr = RFPerUnits( RF_Per )
%=======================================================================
   function WrDELsTxt
   % Create a file containing a table of damage-equivalent loads.
   % Table is in plain-text format for best viewing/printing.


         % Open the file for writing.
         % Add the header information.

      DELfile = [ GetRoot( SettingsFile ), '.dels' ];
      UnD = fopen( DELfile, 'wt' );

      if ( UnD < 0 )
         beep
         error( sprintf( '  Could not open "%s" for writing.', DELfile ) );
      end

      DateTime = clock;

      fprintf( UnD, '\nThese damage-equivalent loads were generated by %s on %s at %02d:%02d:%02d.\n\n', ProgName, date, uint8( DateTime(4:6) ) );


         % Generate the header of the table.

      if ( FileInfo.HaveUnits )
         fprintf( UnD, [ StrFmtL, ' ', StrFmtL, ' S/N Slope ' ], 'Channel', 'Units' );
      else
         fprintf( UnD, [ StrFmtL, ' S/N Slope ' ], 'Channel' );
      end % if

      if ( NumFiles == 1 )

         fprintf( UnD, [ StrFmt, '\n' ], 'DEL' );

      else

         fprintf( UnD, StrFmt, 'Aggregate' );

         NumStr = sprintf( '%d', ceil( log10( NumFiles ) ) );

         for File=1:NumFiles
            fprintf( UnD, [ ' ', StrFmt ], sprintf( [ 'File%', NumStr, 'd' ], File ) );
         end % for File

         fprintf( UnD, '\n' );

      end % if


         % Generate the body of the table.

      for Ch=1:NumFatChan

%TODO: Deal with multiple slopes.
         if ( FileInfo.HaveUnits )
            fprintf( UnD, [ StrFmtL, ' ', StrFmtL, ' %9g' ], Fatigue.ChanInfo(Ch).ChanName, FileInfo.Units{Fatigue.ChanInfo(Ch).Chan}, Fatigue.ChanInfo(Ch).SNslopes );
         else
            fprintf( UnD, [ StrFmtL, ' %9g' ], Fatigue.ChanInfo(Ch).ChanName, Fatigue.ChanInfo(Ch).SNslopes );
         end % if

         if ( NumFiles == 1 )

            fprintf( UnD, [ ' ', RealFmt, '\n' ], Fatigue.File(1).RF(Ch).DEL );

         else

            fprintf( UnD, [ ' ', RealFmt ], Fatigue.Agg.RF(Ch).DEL );

            for File=1:NumFiles
               fprintf( UnD,  [ ' ', RealFmt ], Fatigue.File(File).RF(Ch).DEL );
            end % for File

            fprintf( UnD, '\n' );

         end % if

      end % for


         % Create a list of file names.

      fprintf( UnD, '\n' );

      if ( NumFiles == 1 )
         fprintf( UnD, 'File: %s\n', FileInfo.FileName{1} );
      else
         for File=1:NumFiles
            fprintf( UnD, [ 'File%', NumStr, 'd: %s\n' ], File, FileInfo.FileName{File} );
         end % for
      end % if


         % Close the DEL file.

      fclose( UnD );

      return


   end % function WrDELsTxt
%=======================================================================
   function WrDELsXLS
   % Create an Excel workbook containing tables of damage-equivalent loads.


         % Set up the name of the Excel file.  Delete the file if it already exists

      XLSfile = [ GetRoot( SettingsFile ), '_DELs.xls' ];

      fprintf( '    Writing DELs to "%s".\n', XLSfile );

      DelFile( XLSfile );


         % Turn off warnings regarding adding sheets to the workbook.

      warning off MATLAB:xlswrite:AddSheet


         % Get the date and time.

      DateTime = clock;
      Date     = date;


         % Create the header.  It includes the aggregate if there were multiple files.

      if ( NumFiles == 1 )

         SheetInfo      = cell( NumFatChan+NumFiles+4, 4 );
         SheetInfo{1}   = sprintf( 'These damage-equivalent loads were generated by %s on %s at %02d:%02d:%02d.', ProgName, Date, uint8( DateTime(4:6) ) );
         SheetInfo{3,1} = 'Channel';
         SheetInfo{3,2} = 'Units';
         SheetInfo{3,3} = 'S/N Slope';
         SheetInfo{3,4} = 'DEL';

      else

         SheetInfo      = cell( NumFatChan+NumFiles+4, NumFiles+4 );
         SheetInfo{1}   = sprintf( 'These damage-equivalent loads were generated by %s on %s at %02d:%02d:%02d.', ProgName, Date, uint8( DateTime(4:6) ) );
         SheetInfo{3,1} = 'Channel';
         SheetInfo{3,2} = 'Units';
         SheetInfo{3,3} = 'S/N Slope';
         SheetInfo{3,4} = 'Aggregate';
         NumStr         = sprintf( '%d', ceil( log10( NumFiles ) ) );

         for File=1:NumFiles
            SheetInfo{3,File+4} = sprintf( [ 'File%', NumStr, 'd' ], File );
         end % for File

      end % if


         % Generate the body of the table and the list of file names.

      for Ch=1:NumFatChan

         SheetInfo{Ch+3,1} = Fatigue.ChanInfo(Ch).ChanName;
         SheetInfo{Ch+3,2} = FileInfo.Units{Fatigue.ChanInfo(Ch).Chan};
%TODO: Deal with multiple slopes.
         SheetInfo{Ch+3,3} = Fatigue.ChanInfo(Ch).SNslopes;

         if ( NumFiles == 1 )

            SheetInfo{Ch+3,4} = Fatigue.File(1).RF(Ch).DEL;

         else

            SheetInfo{Ch+3,4} = Fatigue.Agg.RF(Ch).DEL;

            for File=1:NumFiles
               SheetInfo{Ch+3,File+4} = Fatigue.File(File).RF(Ch).DEL;
            end % for File

         end % if

      end % for


         % Create a list of file names.

      if ( NumFiles == 1 )
         SheetInfo{NumFatChan+5,1} = [ 'File: ', FileInfo.FileName{1} ];
      else
         for File=1:NumFiles
            SheetInfo{NumFatChan+File+5,1} = sprintf( [ 'File%', NumStr, 'd: %s' ], File, FileInfo.FileName{File} );
         end % for
      end % if


         % Create the workbook.

      xlswrite( XLSfile, SheetInfo, 'DELs', 'A2' );


         % Delete the blank sheet, "Sheet1".

      DelSheet1( XLSfile );


      return

   end % function WrDELsXLS
%=======================================================================
   function WrRFTxt
   % Create a file containing a table of damage-equivalent loads.
   % Table is in plain-text format for best viewing/printing.

      global AggRoot


         % Set up the header that is common for all files.

      DateTime = clock;

      if ( Fatigue.BinCycles )
         Type = 'binned';
      else
         Type = 'raw';
      end % if

      if ( Fatigue.CumFatigue && ~Fatigue.BinMeans )
         RMCumStr = ', cumulative';
      else
         RMCumStr = '';
      end % if
      if ( Fatigue.BinMeans )
         RMCumStr = ', range-mean';
      elseif ( Fatigue.CumFatigue )
         RMCumStr = ', cumulative';
      else
         RMCumStr = '';
      end % if

      Head = sprintf( 'These %s%s rainflow cycles were generated by %s on %s at %02d:%02d:%02d.', Type, RMCumStr, ProgName, date, uint8( DateTime(4:6) ) );

      fprintf( '    Writing %s%s rainflow cycles to:\n', Type, RMCumStr );


         % Create an output file for each data file and the aggregate if more than one file.

      if ( NumFiles == 1 )
         FirstFile = 1;
      else
         FirstFile = 0;
      end % if

      for File=FirstFile:NumFiles


            % Load the SheetInfo cell array with data to send to the workbook.

         if ( Fatigue.BinMeans )

            NumRBins = zeros( 1, NumFatChan );
            NumMBins = zeros( 1, NumFatChan );

            if ( File == 0 )

               RFfile = [ AggRoot, '.rflo' ];

               for Ch=1:NumFatChan

                  RFC{Ch} = Fatigue.Agg.RF(Ch).Bins;

                  NumRBins(Ch) = Fatigue.Agg.RF(Ch).NumRBins;
                  NumMBins(Ch) = Fatigue.Agg.RF(Ch).NumMBins;

               end % for Ch

            else % ( File ~= 0 )

               RFfile = [ GetRoot( FileInfo.FileName{File} ), '.rflo' ];

               for Ch=1:NumFatChan

                  RFC{Ch} = Fatigue.File(File).RF(Ch).Bins;

                  NumRBins(Ch) = Fatigue.File(File).RF(Ch).NumRBins;
                  NumMBins(Ch) = Fatigue.File(File).RF(Ch).NumMBins;

               end % for Ch

            end % if ( File == 0 )


               % Write out the 2-D data to RFfile.

            Write2D;

         else % ( ~Fatigue.BinMeans )

            if ( File == 0 )

               RFfile = [ AggRoot, '.rflo' ];

               if ( Fatigue.BinCycles )

                  if ( Fatigue.CumFatigue )
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.Agg.RF(Ch).CumCycles;
                     end % for Ch
                  else
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.Agg.RF(Ch).Bins;
                     end % for Ch
                  end % if ( Fatigue.CumFatigue )

                  NumRBins = Fatigue.Agg.RF(Ch).NumRBins;
                  NumMBins = Fatigue.Agg.RF(Ch).NumMBins;

               else % ( ~Fatigue.BinCycles )

                  if ( Fatigue.CumFatigue )
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.Agg.RF(Ch).CumCycles;
                     end % for Ch
                  else
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.Agg.RF(Ch).Cycles(:,3:4);
                     end % for Ch
                  end % if ( Fatigue.CumFatigue )

               end % if ( Fatigue.BinCycles )

            else % ( File ~= 0 )

               RFfile = [ GetRoot( FileInfo.FileName{File} ), '.rflo' ];

               if ( Fatigue.BinCycles )

                  if ( Fatigue.CumFatigue )
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.File(File).RF(Ch).CumCycles;
                     end % for Ch
                  else
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.File(File).RF(Ch).Bins;
                     end % for Ch
                  end % if ( Fatigue.CumFatigue )

                  NumRBins = Fatigue.File(File).RF(Ch).NumRBins;
                  NumMBins = Fatigue.File(File).RF(Ch).NumMBins;

               else % ( ~Fatigue.BinCycles )

                  if ( Fatigue.CumFatigue )
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.File(File).RF(Ch).CumCycles;
                     end % for Ch
                  else
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.File(File).RF(Ch).Cycles(:,3:4);
                     end % for Ch
                  end % if ( Fatigue.CumFatigue )

               end % if ( Fatigue.BinCycles )

            end % if ( File == 0 )


               % Write out the 1-D data to RFfile.  Close it when done.

            Write1D;

         end % if ( Fatigue.BinMeans )

      end % for File

      fprintf( '    Done.\n' );

      return
      %=======================================================================
%TODO: Deal with multiple slopes.
      function Write1D
      % Write the output file using 1-D data from RFC.


               % Open the output file.

         UnR = fopen( RFfile, 'wt' );

         if ( UnR < 0 )
            beep
            error( sprintf( '  Could not open "%s" for writing.', RFfile ) );
         end

         fprintf( UnR, '\n%s\n\n', Head );
         fprintf( UnR, 'The -x values are the peak-to-peak cycle ranges.\n' );

         if ( Fatigue.CumFatigue )
            fprintf( UnR, 'The -y values are the cumulative %s.\n\n', lower( Fatigue.RFPerStr ) );
         else
            fprintf( UnR, 'The -y values are the %s.\n\n', lower( Fatigue.RFPerStr ) );
         end % if

         fprintf( '      %s\n', RFfile );


            % Create the column headings.

         for Ch=1:NumFatChan
            fprintf( UnR, [ ' ', StrFmt, '-x' ],  Fatigue.ChanInfo(Ch).ChanName );
            fprintf( UnR, [ ' ', StrFmt, '-y' ],  Fatigue.ChanInfo(Ch).ChanName );
         end % for Ch

         fprintf( UnR, '\n' );


            % Write out the cycles.

         MaxRows = max( arrayfun( @(x)length( RFC{x} ), 1:length( RFC ) ) );

         for Row=1:MaxRows

            for Ch=1:NumFatChan
               if ( Row <= length(  RFC{Ch} ) )
                  fprintf( UnR, [ '   ', RealFmt, '   ', RealFmt ], RFC{Ch}(Row,1), RFC{Ch}(Row,2) );
               else
                  fprintf( UnR, [ '   ', StrFmt, '   ', StrFmt ], ' ', ' ' );
               end % if
            end % for Ch

            fprintf( UnR, '\n' );

         end % for Row

         fclose( UnR );

         return

      end % function Write1D
      %=======================================================================
      function Write2D
      % Write the output file using 2-D data from RFC.


               % Open the output file.

         UnR = fopen( RFfile, 'wt' );

         if ( UnR < 0 )
            beep
            error( sprintf( '  Could not open "%s" for writing.', RFfile ) );
         end


            % Generate the header.

         fprintf( UnR, '\n%s\n\n', Head );
         fprintf( UnR, 'Counts were generated for ranges and means.\n' );
         fprintf( UnR, '  Row values are the cycle peak-to-peak magnitudes.\n' );
         fprintf( UnR, '  Column values are the cycle means.\n' );
         fprintf( UnR, '  Table values are the rainflow %s.\n', lower( Fatigue.RFPerStr ) );

         fprintf( '      %s\n', RFfile );


            % Generate a table for each channel.

         for Ch=1:NumFatChan

            fprintf( UnR, '\n\n==========================================================================\n' );
            fprintf( UnR, 'For %s %s:\n\n', Fatigue.ChanInfo(Ch).ChanName, cell2mat( FileInfo.Units(Fatigue.ChanInfo(Ch).Chan) ) );

            fprintf( UnR, [ StrFmt, ' ', StrFmt, '\n', StrFmt ], ' ', 'Means ->', 'Ranges' );

            for Col=1:NumMBins(Ch)
               if ( File == 0 )
                  fprintf( UnR, [ ' ', RealFmt ], Fatigue.Agg.RF(Ch).MBinVals(Col) );
               else
                  fprintf( UnR, [ ' ', RealFmt ], Fatigue.File(File).RF(Ch).MBinVals(Col) );
               end % if
            end % for Col

            fprintf( UnR, '\n' );

            for Row=1:NumRBins(Ch)

               if ( File == 0 )
                  fprintf( UnR, RealFmt, Fatigue.Agg.RF(Ch).RBinVals(Row) );
               else
                  fprintf( UnR, RealFmt, Fatigue.File(File).RF(Ch).RBinVals(Row) );
               end % if

               for Col=1:NumMBins(Ch)
                  fprintf( UnR, [ ' ', RealFmt ], RFC{Ch}(Row,Col) );
               end % for Col

               fprintf( UnR, '\n' );

            end % for Row

         end % for Ch

         fclose( UnR );

         return

      end % function Write2D
   %=======================================================================

   end % function WrRFTxt
%=======================================================================
   function WrRFXLS
   % Create an Excel workbook containing tables of rainflow cycles.

   % If CumFatigue was enabled, cumulative fatigue cycles will be written.
   % If binning was requested, binned cycles will be written.


         % See if the user requested more than 128 channels.  Excel 2003 can
         % have only 256 columns ans each channel takes two columns.
         % This does not matter if mean bins were created.

      if ( ( NumFatChan > 128 ) && ~Fatigue.BinMeans )
         beep;
         error( [ '  When creating Excel workbooks of rainflow cycles, if mean bins are not used', ...
                  '  you cannot have more than 128 channels due to limitations in Excel 2003.' ] );
      end % if


         % Set up the name of the Excel file.  Delete the file if it already exists

      XLSfile = [ GetRoot( SettingsFile ), '_RFCs.xlsx' ];

      DelFile( XLSfile );

      if ( Fatigue.BinCycles )
         Type = 'binned';
      else
         Type = 'raw';
      end % if

      if ( Fatigue.CumFatigue && ~Fatigue.BinMeans )
         RMCumStr = ', cumulative';
      else
         RMCumStr = '';
      end % if
      if ( Fatigue.BinMeans )
         RMCumStr = ', range-mean';
      elseif ( Fatigue.CumFatigue )
         RMCumStr = ', cumulative';
      else
         RMCumStr = '';
      end % if

      fprintf( '    Writing %s%s rainflow cycles to "%s".\n', Type, RMCumStr, XLSfile );


         % Get the date and time.

      DateTime = clock;
      Date     = date;


         % Create the header.

      Head = sprintf( 'These %s%s rainflow cycles were generated by %s on %s at %02d:%02d:%02d.', Type, RMCumStr, ProgName, Date, uint8( DateTime(4:6) ) );


         % Turn off warnings regarding adding sheets to the workbook.

      warning off MATLAB:xlswrite:AddSheet


         % Create a sheet for each file and the aggregate if more than one file.

      if ( NumFiles == 1 )
         FirstFile = 1;
      else
         FirstFile = 0;
      end % if

      for File=FirstFile:NumFiles


            % Load the SheetInfo cell array with data to send to the workbook.

         if ( Fatigue.BinMeans )

            NumRBins = zeros( 1, NumFatChan );
            NumMBins = zeros( 1, NumFatChan );

            if ( File == 0 )

               Sheet = 'Aggregate';

               for Ch=1:NumFatChan

                  RFC{Ch} = Fatigue.Agg.RF(Ch).Bins;

                  NumRBins(Ch) = Fatigue.Agg.RF(Ch).NumRBins;
                  NumMBins(Ch) = Fatigue.Agg.RF(Ch).NumMBins;

               end % for Ch


                  % Load the SheetInfo array for writing to the Excel workbook.

               SheetInfo = GenInfo2D;

            else % ( File ~= 0 )

               Sheet = GetRoot( FileInfo.FileName{File} );

               for Ch=1:NumFatChan

                  RFC{Ch} = Fatigue.File(File).RF(Ch).Bins;

                  NumRBins(Ch)   = Fatigue.File(File).RF(Ch).NumRBins;
                  NumMBins(Ch)   = Fatigue.File(File).RF(Ch).NumMBins;

               end % for Ch


                  % Load the SheetInfo array for writing to the Excel workbook.

               SheetInfo = GenInfo2D;

            end % if ( File == 0 )

         else % ( ~Fatigue.BinMeans )

            if ( File == 0 )

               Sheet = 'Aggregate';

               if ( Fatigue.BinCycles )
                  if ( Fatigue.CumFatigue )
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.Agg.RF(Ch).CumCycles;
                     end % for Ch
                  else
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.Agg.RF(Ch).Bins;
                     end % for Ch
                  end % if ( Fatigue.CumFatigue )
               end % if ( Fatigue.BinCycles )

            else % ( File ~= 0 )

               Sheet = GetRoot( FileInfo.FileName{File} );

               if ( Fatigue.BinCycles )
                  if ( Fatigue.CumFatigue )
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.File(File).RF(Ch).CumCycles;
                     end % for Ch
                  else
                     for Ch=1:NumFatChan
                        RFC{Ch} = Fatigue.File(File).RF(Ch).Bins;
                     end % for Ch
                  end % if ( Fatigue.CumFatigue )
               end % if ( Fatigue.BinCycles )

            end % if ( File == 0 )


               % Load the SheetInfo array.

            SheetInfo = GenInfo1D;

         end % if ( Fatigue.BinMeans )


            % Write the SheetInfo cell array to the workbook.

         xlswrite( XLSfile, SheetInfo, Sheet, 'A2' );

      end % for File


         % Delete the blank sheet, "Sheet1".

      DelSheet1( XLSfile );


      return

      %=======================================================================
      function [ Info ] = GenInfo1D
      % Create the Info cell array using 1-D data from RFC.


         MaxRows = max( arrayfun( @(x)length( RFC{x} ), 1:length( RFC ) ) );

         Info = cell( MaxRows+6, 2*NumFatChan );

         Info{1} = Head;
         Info{3} = 'The -x values are the peak-to-peak cycle ranges.';

         if ( Fatigue.CumFatigue )
            Info{4} = sprintf( 'The -y values are the cumulative %s.', lower( Fatigue.RFPerStr ) );
         else
            Info{4} = sprintf( 'The -y values are the %s.', lower( Fatigue.RFPerStr ) );
         end % if

         for Ch=1:NumFatChan

            ColY = 2*Ch;

            Info{6,ColY-1} = [ Fatigue.ChanInfo(Ch).ChanName, '-x' ];
            Info{6,ColY  } = [ Fatigue.ChanInfo(Ch).ChanName, '-y' ];

            NumRows = length( RFC{Ch} );

            for Row=1:NumRows
               Info{Row+6,ColY-1} = RFC{Ch}(Row,1);
               Info{Row+6,ColY  } = RFC{Ch}(Row,2);
            end % for Row

         end % for Ch

         return

      end % function Info = GenInfo1D
      %=======================================================================
      function [ Info ] = GenInfo2D
      % Create the Info cell array using 2-D data from RFC.


            % Allocate the info array.

            % For this tab in the workbook, we will generate tables for each channel of data.
            % Because channels my have a different number of mean bins, we need to size the
            % Info array so it can hold the channel with the most mean bins..

         MaxCols = max( [ NumMBins ] ) + 1;
         MaxRows = sum( [ NumRBins ] ) + 8*NumFatChan + 3;

         Info = cell( MaxRows, MaxCols );


            % Fill the Info array.

         Info{1} = Head;
         Info{3} = 'Counts were generated for ranges and means.';
         CurRow  = 3;

         for Ch=1:NumFatChan

            CurRow           = CurRow + 3;
            Info{CurRow  }   = '''==========================================================================';
            Info{CurRow+1}   = sprintf( 'For %s %s:', Fatigue.ChanInfo(Ch).ChanName, cell2mat( FileInfo.Units(Fatigue.ChanInfo(Ch).Chan) ) );
            Info{CurRow+2,2} = 'Row values are the cycle peak-to-peak magnitudes.';
            Info{CurRow+3,2} = 'Column values are the cycle means.';
            Info{CurRow+4,2} = sprintf( 'Table values are the rainflow %s.', lower( Fatigue.RFPerStr ) );

            for Col=1:NumMBins(Ch)
               if ( File == 0 )
                  Info{CurRow+6,Col+1} = Fatigue.Agg.RF(Ch).MBinVals(Col);
               else
                  Info{CurRow+6,Col+1} = Fatigue.File(File).RF(Ch).MBinVals(Col);
               end % if
            end % for Col

            CurRow = CurRow + 6;

            for Row=1:NumRBins(Ch)

               if ( File == 0 )
                  Info{CurRow+Row,1} = Fatigue.Agg.RF(Ch).RBinVals(Row);
               else
                  Info{CurRow+Row,1} = Fatigue.File(File).RF(Ch).RBinVals(Row);
               end % if

               for Col=1:NumMBins(Ch)
                  Info{CurRow+Row,Col+1} = RFC{Ch}(Row,Col);
               end % for Col

            end % for Row

            CurRow = CurRow + NumRBins(Ch);

         end % for Ch

         return

      end % function Info = GenInfo2D
   %=======================================================================
   end % function WrRFXLS
%=======================================================================
end % CompFatiguee( SettingsFile )
