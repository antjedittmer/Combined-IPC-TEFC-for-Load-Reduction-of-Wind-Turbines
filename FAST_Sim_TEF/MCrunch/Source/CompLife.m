function CompLife( SettingsFile )
% Perform a fatigue-life anaylsis.
%
% For now, it does a rainflow analysis and calculates fatigue life that is weighted
% by a probability distribution.
%
% Syntax is:  CompLife( SettingsFile );
%
% Example:
%     CompLife( 'MySettings.mcru' );
%
% See also DelFile, GetRoot, MCrunch, ReadSettings

   global FileInfo Fatigue ProgName RealFmt StrFmt StrFmtL


      % Tell the user we are doing a fatigue analysis.

   fprintf( '\n  Performing fatigue-life analysis.\n' );


      % Eliminate any selected channels that are constant or determine the number of bins
      % if we are binning the cycles.

   NumFatChan = size( Fatigue.ChanInfo , 2 );
   NumFiles   = size( FileInfo.FileName, 1 );

   Range  = zeros( 1, NumFatChan );
   Minima = zeros( 1, NumFatChan );
   Maxima = zeros( 1, NumFatChan );

   AllConstant = true;


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
      BegTime                = FileInfo.Time(FileInfo.StartLine(File)                          ,FileInfo.TimeChan);
      EndTime                = FileInfo.Time(FileInfo.StartLine(File)+FileInfo.NumLines(File)-1,FileInfo.TimeChan);
      Fatigue.ElapTime(File) = EndTime - BegTime;
      Fatigue.Time(WSbin)    = Fatigue.Time(WSbin) + Fatigue.ElapTime(File);
   end % for File


   for Ch=1:NumFatChan

      Chan                          = Fatigue.ChanInfo(Ch).Chan;
      Fatigue.ChanInfo(Ch).ChanName = FileInfo.Names{Chan};

      Range (Ch) = FileInfo.Stats.AggRange (Chan);
      Minima(Ch) = FileInfo.Stats.AggMinima(Chan);
      Maxima(Ch) = FileInfo.Stats.AggMaxima(Chan);

   end % for Ch


      % See if all the channels have constant data.  If so, we are done.

   if ( max( Range ) == 0.0 )
      beep;
      error( '\n  All selected fatigue columns have constant data.  Fatigue calculations skipped.\n' );
   end % if


      % Delete any old information.  Create the Cycles and Bins branches.

   Fatigue.File(NumFiles).RF(NumFatChan) = struct( 'NumCCycles', [], 'Cycles', [], 'Bins', [] );


      % Set the string for the RF period.

   Fatigue.RFPerStr = RFPerUnits( Fatigue.RF_Per );


      % Process all the files.

   for File=1:NumFiles


         % If we are binning cycles, determine the time scale factor.
         % We are assuming that the data has a constant time step and
         % that the first file has at least to time steps.

      fprintf( '    Performing fatigue analysis for "%s":\n', FileInfo.FileName{File} );
      NumLines = FileInfo.NumLines(File) - 1;

      TimeFact = Fatigue.RF_Per/Fatigue.ElapTime(File);


         % Loop through the channels.  Cycle count, then bin the cycles if requested.

      for Ch=1:size( Fatigue.ChanInfo, 2 )

         Chan = Fatigue.ChanInfo(Ch).Chan;

         fprintf( '      %s:', FileInfo.Names{Chan} )

         [ Fatigue.File(File).RF(Ch).Cycles, Fatigue.File(File).RF(Ch).DEL, Fatigue.File(File).RF(Ch).Bins ] = Rainflow( File, Ch, Range(Ch), TimeFact, Fatigue.ChanInfo(Ch).SNslopes );

      end % for Ch

   end % for File


      % Do the lifetime calculations.

   CompLife( File, Ch );

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
%               LifeCycles         = Fatigue.WSProb(WSbin)*Fatigue.File(File).RF(Ch).Bins(Bin)*Fatigue.ElapTime(File)/Fatigue.Time(WSbin);
               LifeCycles         = Fatigue.WSProb(WSbin)*Fatigue.File(File).RF(Ch).Bins(Bin)*Fatigue.RF_Per/Fatigue.Time(WSbin);
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

      TSlen   = FileInfo.NumLines(File);
      TimeSer = FileInfo.Time(FileInfo.StartLine(File):FileInfo.StartLine(File)+TSlen-1,Chan);


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


         % Bin the cycles.

      fprintf( '  Binning cycles.\n' );


         % Set up the bins.

            % If we are binning means, bin the variable-mean cycle ranges (col=1).  If not, bin the
            % fixed-mean cycle ranges (col=3).

            % Do this only on the first pass for this channel.

            % NOTE: In the future, we may ask the user what fraction of the bin
            % width should be the reported value.  To be conservative, we should
            % report the most-positive end of the bin.

      Fatigue.File(File).RF(Ch).NumRBins = ceil( max( Cycles(:,3) )/Fatigue.ChanInfo(Ch).BinWidth );

      NumRBins = Fatigue.File(File).RF(Ch).NumRBins;

      Fatigue.File(File).RF(Ch).RBinVals = ( (1:NumRBins) - 0.5 )*Fatigue.ChanInfo(Ch).BinWidth;


         %Initialize the array.

      Bins = zeros( NumRBins, 1 );


         % Bin the cycles.  Increment the bin count by the time-factored cycle weight.
%NOTE: Should we just count cycles instead of normalizing with TimeFact?

      for Cyc=1:size( Cycles, 1 );
         RInd         = ceil( Cycles(Cyc,3)/Fatigue.ChanInfo(Ch).BinWidth );
%         Bins(RInd,1) = Bins(RInd,1) + TimeFact*Cycles(Cyc,4);
         Bins(RInd,1) = Bins(RInd,1) + Cycles(Cyc,4);
      end % for Cyc


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
end % CompFatiguee( SettingsFile )
