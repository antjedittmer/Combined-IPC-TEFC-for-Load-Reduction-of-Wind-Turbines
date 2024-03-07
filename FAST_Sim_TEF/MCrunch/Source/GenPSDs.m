function GenPSDs( SettingsFile )
% Generate power spectral densities of time series.
%
% It does this for the data in individual files and, if there is more than one file,
% it will also computer the averages of the PSDs (not the PSDs of the aggregates).
%
% Syntax is:  GenPSDs( SettingsFile )
%
%     where:
%        SettingsFile: A string array containing the name of the MCrunch settings
%                      file use for this analysis.
%
% Example:
%     GenPDFs( 'MySettings.mcru' )
%
% See also DelFile, DelSheet1, GetRoot, MCrunch, ReadSettings


   global FileInfo ProgName PSD RealFmt StrFmt


      % Let user know what we are doing.

   fprintf( '  Generating PSDs.\n' );

   if ( PSD.Detrend )
      fprintf( '    Detrending enabled.\n' );
   elseif ( PSD.RmvMean )
      fprintf( '    Mean removal enabled.\n' );
   end % if

   if ( PSD.CosTaper )
      fprintf( '    Cosine taper enabled.\n' );
   end % if

   fprintf( '    Using %s windows.\n', PSD.WindowType );

   if ( PSD.IntPSDs )
      fprintf( '    PSD integration enabled.\n' );
   end % if

%   if ( PSD.FiltPSDs )
%      fprintf( '    PSD filtering enabled.\n' );
%   end % if

   if ( PSD.BinPSDs )
      fprintf( '    PSD binning enabled.\n' );
   end % if

   NumChans    = size( PSD.PSDChans     , 2 );
   NumFiles    = size( FileInfo.FileName, 1 );
   TC          = FileInfo.TimeChan;
   SampRate    = 1.0/( FileInfo.Time(2,TC) - FileInfo.Time(1,TC) );
   WindowSize  = 25;


      % If we have multiple files all of the same length, or if we are binning, we can average the PSDs.

   if ( NumFiles > 1 )
      DoAverage = true;
      for File=2:NumFiles
         if ( FileInfo.NumLines(File) ~= FileInfo.NumLines(1) )
            DoAverage = false;
            break
         end % if
      end % for File
   else
      DoAverage = false;
   end % if


      % If we are binning the PSDs, we need only one copy of the frequencies
      % for the aggregate and all files.  Set them to the bin centers.

   if ( PSD.BinPSDs )

      DoAverage = true;
      NumBins   = ceil( 0.5*SampRate/PSD.BinWidth );
      PSD.Freqs = ( (1:NumBins) - 0.5 )'*PSD.BinWidth;

      if ( NumFiles > 1 )
         for File=1:NumFiles
            PSD.File(File).PSDs = zeros( NumBins, NumChans );
         end % for File
      else
         PSD.File(1).PSDs = zeros( NumBins, NumChans );
      end % if

   end % if


      % Set up running average filter.

   HwindowSize = floor( WindowSize/2 ); %half of the window size
   filt1       = ones( 1, HwindowSize )/HwindowSize;


      % Set up the cell array for the spectrum type.

   switch ( PSD.WindowType )
      case ( 'barlett' )
         Window = { PSD.WindowType, WindowSize };
      case ( 'hamming' )
         Window = PSD.WindowType;
      otherwise
            beep;
            error( '\n  Invalid PSD window type (WindowType).\n' );
   end % switch


      % Generate PSDs for each file.  File=0 is for the aggregate.

   for File=1:NumFiles

      FLine = FileInfo.StartLine(File);
      LLine = FLine + FileInfo.NumLines(File) - 1;
      TSlen = FileInfo.NumLines(File);


         % Process the requested channels.

      for Ch=1:NumChans

         PSDChan = PSD.PSDChans(Ch);
         TimeSer = FileInfo.Time(FLine:LLine,PSDChan);


            % Detrend the data or remove the mean.

         if ( PSD.Detrend )
            TimeSer = detrend( TimeSer );
         elseif ( PSD.RmvMean )
            TimeSer = TimeSer - mean( TimeSer );
         end % if


            % Taper the first and last 5% of the records with a cosine taper.
            % This reduces the level of white noise in the signal due to the finite length of the signal.

         if ( PSD.CosTaper )
            LenTap         = round( 0.05*TSlen );
            TapIX          = 1:LenTap;
            Taper          = [ 0.5*( 1 - cos( double( TapIX )*pi/double( LenTap ) ) ), zeros( 1, 2*LenTap ) ];
            Taper          = [ Taper(1:LenTap), Taper(LenTap:-1:1) ];               %the taper, bringing the signal to zero at the endpoints
            TapIX          = round( [ TapIX, TapIX+(TSlen-LenTap) ] );  %the indicies to taper
            TimeSer(TapIX) = TimeSer(TapIX).*Taper(:);
         end % if


            % Set up the spectrum object and specify the window type.
            % Generate the PSD.

         HdlSp = spectrum.periodogram( Window );
         HdlOp = psdopts( HdlSp );

         set( HdlOp, 'Fs',SampRate, 'SpectrumType','onesided', 'NFFT',double( TSlen ) );

         HdlPSD   = psd( HdlSp, TimeSer, HdlOp );
         NumFreqs = length( HdlPSD.Frequencies );


            % Should we filter or integrate the PSD data?  The second frequence is the frequency step.

         if ( PSD.IntPSDs )
            ThisPSD = cumtrapz( HdlPSD.Data )*HdlPSD.Frequencies(2);
         else
            ThisPSD = HdlPSD.Data;
         end % if

 %        if ( PSD.FiltPSDs )
 %           ThisPSD = filtfilt( filt1, 1, ThisPSD ); % 2-pass running-average filter w/ no phase shift; I'm sure there is a better function for this
 %        end % if


            % Bin the PSDs if requested?

         if ( PSD.BinPSDs )

            if ( PSD.BinWidth < HdlPSD.Frequencies(2) )
               beep;
               error( sprintf( '  When binning PSDs (BinPSDs), the user-specified bin width (BinWidth)\n  must be >= the frequency step size from the PSD (1/(2*Tmax)).' ) );
         %      error( '  When binning PSDs (BinPSDs), the user-specified bin width (BinWidth)\n  must be >= the frequency step size from the PSD (1/(2*Tmax)).' );
            end % if

            CurBin   = 1;
            BinMax   = CurBin*PSD.BinWidth;
            NPts     = 0;

            for Freq=1:NumFreqs


                  % If we've moved past the last bin we were filling.  Compute the average and move to the next bin.

               if ( HdlPSD.Frequencies(Freq) > BinMax )

                  PSD.File(File).PSDs(CurBin,Ch) = PSD.File(File).PSDs(CurBin,Ch)/NPts;

                  NPts   = 0;
                  CurBin = CurBin + 1;
                  BinMax = CurBin*PSD.BinWidth;

               end % if


                  % Add this point to the currrent bin.

               NPts = NPts + 1;

               PSD.File(File).PSDs(CurBin,Ch) = PSD.File(File).PSDs(CurBin,Ch) + ThisPSD(Freq);

            end % for Freq


               % Compute the average for the last bin.

            PSD.File(File).PSDs(CurBin,Ch) = PSD.File(File).PSDs(CurBin,Ch)/NPts;

         else


                  % We are not binning.  Store the frequencies and PSDs.

            if ( Ch == 1 )
               PSD.File(File).Freqs = HdlPSD.Frequencies;
            end % if

            PSD.File(File).PSDs(:,Ch) = ThisPSD;

         end % if ( PSD.BinPSDs )

      end % for Ch

   end % for File


      % Average the results if appropriate.

   if ( DoAverage )

      PSD.Aver.PSDs = PSD.File(1).PSDs;

      for File=2:NumFiles
         PSD.Aver.PSDs = PSD.Aver.PSDs + PSD.File(File).PSDs;
      end % for

      PSD.Aver.PSDs = PSD.Aver.PSDs/NumFiles;

      if ( ~PSD.BinPSDs )
         PSD.Freqs = HdlPSD.Frequencies;
      end % if

   end % if

   fprintf( '  Done.\n' );


      % Plot the data if requested.

   if ( ~isempty( PSD.Plots ) )
      GenPSDPlots;
   end % if


      % Write the data to an Excel file if requested.

   if ( PSD.WrXLS )
      WrXLS;
   end % if


      % Write the data to a simple text file if requested.

   if ( PSD.WrTxt )
      WrTxt;
   end % if

   return
   %===============================================================================
   function GenPSDPlots
   % Plot power spectral densities.

      global ChartPosition LineWidth PlotColors SaveFigs

      PlotColors = [ 'r', 'b', 'c', 'm', 'g', 'k', 'y', 'w' ];

      fprintf( '  Generating PSDs plots.\n' );


         % Plot the figure(s).

      for Fig=1:size( PSD.Plots, 2 )


            % Create a temporary figure that holds the title, which is generated by the text() function.
            % Save the size of the title for creation later.  This gets around a problem that sometimes
            %  the title() function wraps the text.

         HdlFig = figure( 50000+Fig );
         close( HdlFig );
         HdlFig = figure( 50000+Fig );
         set( HdlFig, 'Position', ChartPosition );
         Title  = [ 'PSD Plots of ', PSD.Plots(Fig).Name ];
         HdlTxt = text( 0, 0, Title, 'FontName','Trebuchet MS', 'FontSize',16, 'FontWeight','bold', 'Units','normalized' );
         TitPos = get( HdlTxt, 'extent' );
         close( HdlFig );

         fprintf( '    %s\n', Title );


            % Create the permanent figure.

         HdlFig = figure( 50000+Fig );

         set( HdlFig, 'Position', ChartPosition );
         set( HdlFig, 'Color',[1 1 1], 'name',Title, 'NumberTitle','off', 'PaperOrientation','landscape', 'PaperPosition',[0.25 0.25 10.5 8.0], 'PaperType','usletter' );


            % Add an overall title that is centered at the top of the figure.

         HdlTit = annotation('textbox', 'String',Title, 'FontName','Trebuchet MS', 'FontSize',16, 'FontWeight','bold' );
         set( HdlTit, 'Color', [0.0, 0.0, 1.0 ], 'LineStyle','none' );
         set( HdlTit, 'Units','normalized', 'HorizontalAlignment','center', 'VerticalAlignment','top' );
         set( HdlTit, 'Position', [ 0.5*(1-TitPos(3)), 1-TitPos(4), TitPos(3), TitPos(4) ] )

         TitPos = get( HdlTit, 'position' );


            % Generate the PSD plots.

         for SP=1:size( PSD.Plots(Fig).Chans, 2 )

            Ch    = PSD.Plots(Fig).Chans( SP );
            ChInd = uint32( PSD.Plots(Fig).ChanInd(SP) );

            HdlSP(SP) = subplot( PSD.Plots(Fig).NRows, PSD.Plots(Fig).NCols, SP );


               % Add curve for each file to the plot.

            for File=1:NumFiles

               Color = mod( File-1, 5 ) + 1;

               if ( PSD.BinPSDs )
                  semilogy( PSD.Freqs, PSD.File(File).PSDs(:,ChInd), PlotColors(Color), 'LineWidth',LineWidth );
               else
                  semilogy( PSD.File(File).Freqs, PSD.File(File).PSDs(:,ChInd), PlotColors(Color), 'LineWidth',LineWidth );
               end % if

               hold on;

            end % for File

            if ( DoAverage && NumFiles > 1 )
               plot( PSD.Freqs, PSD.Aver.PSDs(:,ChInd), 'k', 'LineWidth', LineWidth );
            end % if

            hold off


               % Label it and make it pretty.

            set( gca, 'FontName','Trebuchet MS', 'FontSize',11, 'FontWeight','bold', 'LineWidth',1.2, 'XColor',[0 0 0], 'YColor',[0 0 0] );
            grid on;

            xlabel( 'Frequency, Hz', 'FontName','Trebuchet MS', 'FontSize',14, 'FontWeight','bold' );
            if ( FileInfo.HaveNames )
               ylabel( [ 'PSD of ', FileInfo.Names{Ch} ], 'FontName','Trebuchet MS', 'FontSize',14, 'FontWeight','bold' );
            else
               ylabel( 'PSD', 'FontName','Trebuchet MS', 'FontSize',14, 'FontWeight','bold' );
            end % if

            set( HdlFig, 'Position', ChartPosition );

         end % for SP


            % Create the legend and put it at the top-center of the figure.

         if ( NumFiles > 1 )
            if ( DoAverage )
               HdlLeg = legend( [ FileInfo.FileName; 'Average' ], 'interpreter','none', 'FontSize',7, 'location', 'NorthOutside' );
            else
               HdlLeg = legend( FileInfo.FileName, 'interpreter','none', 'FontSize',7, 'location', 'NorthOutside' );
            end % if
            set( HdlLeg, 'Units','normalized' );
            LPos = get( HdlLeg, 'position' );
            set( HdlLeg, 'Position', [ (1-LPos(3))/2, 1-TitPos(4)-LPos(4), LPos(3), LPos(4) ] );
            LPos = get( HdlLeg, 'Position' );
         else
            LPos = zeros( 4, 1 );
         end % if


            % Resize the PSD.Plots so the legend doesn't cover any of them.

         SPht = ( 1.0 - LPos(4) - TitPos(4) - 0.03 )/PSD.Plots(Fig).NRows - 0.1;

         for Row=1:PSD.Plots(Fig).NRows
            for Ch=1:PSD.Plots(Fig).NCols
               SP    = ( Row - 1 )*PSD.Plots(Fig).NCols + Ch;
               SPpos = get( HdlSP(SP), 'position' );
               Yloc  = 0.1 + ( PSD.Plots(Fig).NRows - Row )*( SPht + 0.1 );
               set( HdlSP(SP), 'position', [ SPpos(1), Yloc, SPpos(3), SPht ] );
            end % for Ch
         end % for Row

         if ( SaveFigs )
            saveas( HdlFig, [ Title, '.fig' ] )
         end % if

      end % for Fig

      fprintf( '  Done.\n' );
      return

   end % function GenPSDPlots
   %===============================================================================
   function WrTxt
   % Write the PSDs to a simple text file.


       % Set up the name of the text file.

      TxtFile = [ GetRoot( SettingsFile ), '.psds' ];

      fprintf( '  Writing PSDs to textfile "%s".\n', TxtFile );


         % Open the text file and add a header.

      fid = fopen( TxtFile, 'w' );

      while ( fid < 0 )
         beep;
         HdlDgl = warndlg( sprintf( 'Please close "%s" if it is open in another program such as Excel.', TxtFile ), 'File Locked!', 'replace' );
         uiwait( HdlDgl );
         fid = fopen( TxtFile, 'w' );
      end % while

      DateTime = clock;
      fprintf( fid, '\nThese power spectral densities were generated by %s on %s at %02d:%02d:%02d.\n', ProgName, date, uint8( DateTime(4:6) ) );


         % Create one section for each data file.

      for File=1:NumFiles

     %    fprintf( '    File: "%s"\n', FileInfo.FileName{File} );

         fprintf( fid, '\nPSDs for "%s":\n', FileInfo.FileName{File} );
         fprintf( fid, [ '\n', repmat( StrFmt, 1, NumChans+1 ), '\n' ], 'Frequency', FileInfo.Names{PSD.PSDChans} );
         fprintf( fid, [ repmat( RealFmt, 1, NumChans+1 ), '\n' ], cat( 2, PSD.Freqs, PSD.File(File).PSDs )' );

      end % for File

      fclose( fid );

      return

   end % function WrTxt
   %===============================================================================
   function WrXLS
   % Write the PSDs to an Excel file.


         % Set up the name of the Excel file.  Delete the file if it already exists

      XLSfile = [ GetRoot( SettingsFile ), '_PSDs.xls' ];

      fprintf( '  Writing binned data to "%s".\n', XLSfile );

      DelFile( XLSfile );


         % Turn off warnings regarding adding sheets to the workbook.

      warning off MATLAB:xlswrite:AddSheet


         % Get the date and time.

      DateTime = clock;
      Date     = date;


         % Create a sheet for the average PSDs if averages were requested.

      if ( DoAverage )

         Sheet = 'Average';

         fprintf( '    Sheet: "%s"\n', Sheet );

         NumFrq = length( PSD.Freqs );
         Info   = cell( NumFrq+5, NumChans+1 );

         Info{1}           = sprintf( 'These average power spectral densities were generated by %s on %s at %02d:%02d:%02d.', ProgName, Date, uint8( DateTime(4:6) ) );
         Info{3}           = sprintf( 'The analysis was based upon %d rows from an aggregate of %d files.',  FileInfo.TotLines, NumFiles );
         Info(5,:)         = { 'Frequency', FileInfo.Names{PSD.PSDChans} };
         Info(6:end,1)     = mat2cell( PSD.Freqs    , repmat(1,NumFrq,1), 1 );
         Info(6:end,2:end) = mat2cell( PSD.Aver.PSDs, repmat(1,NumFrq,1), repmat(1,NumChans,1) );

         xlswrite( XLSfile, Info, Sheet, 'A2' );

      end % if


         % Add one sheet for each data file.

      for File=1:NumFiles

         Sheet = GetRoot( FileInfo.FileName{File} );

         fprintf( '    Sheet: "%s"\n', Sheet );

         if ( PSD.BinPSDs )
            NumFrq = length( PSD.Freqs );
         else
            NumFrq = length( PSD.File(File).Freqs );
         end % if
         Info   = cell( NumFrq+5, NumChans+1 );

         Info{1}           = sprintf( 'These power spectral densities for "%s" were generated by %s on %s at %02d:%02d:%02d.', FileInfo.FileName{File}, ProgName, Date, uint8( DateTime(4:6) ) );
         Info{3}           = sprintf( 'The analysis was based upon %d rows.',  FileInfo.NumLines(File) );
         Info(5,:)         = { 'Frequency', FileInfo.Names{PSD.PSDChans} };
         if ( PSD.BinPSDs )
            Info(6:end,1)     = mat2cell( PSD.Freqs, repmat(1,NumFrq,1), 1 );
         else
            Info(6:end,1)     = mat2cell( PSD.File(File).Freqs, repmat(1,NumFrq,1), 1 );
         end % if
         Info(6:end,2:end) = mat2cell( PSD.File(File).PSDs , repmat(1,NumFrq,1), repmat(1,NumChans,1) );

         xlswrite( XLSfile, Info, Sheet, 'A2' );

      end % for File


         % Delete the blank sheet, "Sheet1".

      DelSheet1( XLSfile );


      fprintf( '  Done.\n' );
      return

   end % function WrXLS
%===============================================================================

end % function GenPSDs( SettingsFile )


