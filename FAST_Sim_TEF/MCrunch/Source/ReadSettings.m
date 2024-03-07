% Process an MCrunch-style settings file.
%
% Syntax is:  ReadSettings;
%
% Example:
%     ReadSettings;
%
% See also GetRoot, MCrunch, ReadVal


   FileInfo = [];


      % Open the settings file.

 %  SettingsFile = 'Test_04.mcru';
   UnPa = fopen( SettingsFile, 'rt' );

   if ( UnPa < 1 )
      beep
      error( '  Could not open "%s" for reading.', SettingsFile );
   end % if


      % Read the settings file into a cell array.
      % See if we are specifying channels using channel names or numbers.
      % See if channel names are specified or found in the input files.

   ParamFile = textscan( UnPa, '%s', 'delimiter', '\n' );
   EchoInp   = false;
   StrNames  = cell2mat( ReadVal( ParamFile{1}{ 5}, 'logical', 1, '' , '' ) );
   NumChans  = cell2mat( ReadVal( ParamFile{1}{15}, 'integer', 1, '' , '' ) );


      % See if the user supplied channel names in the parameter-input file or if
      % we should parse them from the last data file.

   if ( NumChans == 0 )
      UserNames = false;
   elseif ( NumChans > 0 )
      UserNames = true;
   else
      beep
      error( '  In the Input-Data Layout section of the parameter file, NumChans must be >= 0.' );
   end % if


      % Determine the number of calculated channels and where the list of the begins.

   NumCChan = cell2mat( ReadVal( ParamFile{1}{NumChans+19}, 'integer', 1, '' , '' ) );
   FirstCC  = NumChans + 22;

   if ( UserNames )


         % Channel names specified in the parameter file.
         % Read them from the cell array containing the parameter file text.

      ChanNames = cell( NumChans+NumCChan, 1 );

      for Chan=1:NumChans
         temp            = textscan( ParamFile{1}{Chan+16}, '%q', 1 );
%         ChanNames{Chan} = [ '$', cell2mat( temp{1} ) ];
         ChanNames{Chan} = cell2mat( temp{1} );
      end % for Chan

   else


         % Channel names specified in the header(s) of the data file(s).
         % Determine the line number of the data file(s) that contain the channel names.
         % Find the last specified data file.  Open it, and read the channel names.

      NamesLine = cell2mat( ReadVal( ParamFile{1}{11}, 'integer', 1, '' , '' ) );


%TODO: Make it so MCrunch uses default name (e.g., "Chan1") if we are getting info from
%      the data files and NamesLine is set to zero.

      if ( NamesLine == 0 )
         beep
         error( '  You must have a line with names (NamesLine) if you want to get information from the data files.' );
      end % if

      for PLine=1:size( ParamFile{1}, 1 )
         if ( ~isempty( strfind( ParamFile{1}{PLine}, '==EOF==' ) ) )
            LastFile = PLine - 1;
            break
         end % if
      end % for PLine

      DataFileName = cell2mat( ReadVal( ParamFile{1}{LastFile}, 'string' , 1, '', '' ) );

      fidData = fopen( DataFileName, 'rt' );

      while ( fidData < 0 )
         beep;
         HdlDgl = warndlg( sprintf( 'Please close "%s" if it is open in another program such as Excel.', DataFileName ), 'File Locked!', 'replace' );
         uiwait( HdlDgl );
         fidData = fopen( DataFileName, 'rt' );
      end % while

      HeadLines  = textscan( fidData, '%s', NamesLine, 'delimiter', '\n' );
      fclose( fidData );
      temp       = textscan( HeadLines{1}{NamesLine}, '%s' );
      NumChans   = size( temp{1}, 1 );
%      NumChansSN = NumChans;
      ChanNames  = cell( 1, NumChans );

      for Ch=1:NumChans
%         ChanNames{Ch} = [ '$', temp{1}{Ch} ];
         ChanNames{Ch} = temp{1}{Ch};
      end % for Ch

   end % if ( UserNames )


      % Add the calculated channel names to the list of channels.

   for Ch=1:NumCChan
%      ChanNames{NumChans+Ch} = [ '$', cell2mat( ReadVal( ParamFile{1}{FirstCC+Ch-1}, 'string' , 1, '' , '' ) ) ];
      ChanNames{NumChans+Ch} = cell2mat( ReadVal( ParamFile{1}{FirstCC+Ch-1}, 'string' , 1, '' , '' ) );
   end % for

   TotChans = NumChans + NumCChan;


   if ( StrNames )


         % Create an cell array of index strings.

      ChanInds = cell( TotChans, 1 );

      for Ch=1:TotChans
         ChanInds{Ch} = num2str( Ch, '%u' );
      end % for Ch


         % Processing the ParamFile cell array, replace all the "$<ChanName>$" strings with
         % the appropriate indices.

      for Ch=1:TotChans
         for PLine=1:size( ParamFile{1}, 1 )
            ParamFile{1}{PLine} = strrep( ParamFile{1}{PLine}, [ '$', ChanNames{Ch}, '$' ], ChanInds{Ch} );
         end % for PLine
      end % for Ch

   end % if (StrNames)


%   if ( StrNames )
%
%
%         % Determine the number of calculated channels and where the list of the begins.
%
%      NumCChan = cell2mat( ReadVal( ParamFile{1}{NumChans+19}, 'integer', 1, '' , '' ) );
%      FirstCC  = NumChans + 22;
%
%      if ( UserNames )
%
%
%            % Channel names specified in the parameter file.
%            % Read them from the cell array containing the parameter file text.
%
%         ChanNames = cell( NumChans+NumCChan, 1 );
%
%         for Chan=1:NumChans
%
%            temp = textscan( ParamFile{1}{Chan+16}, '%q', 1 );
%
%            ChanNames{Chan} = [ '$', cell2mat( temp{1} ), '$' ];
%
%         end % for Chan
%
%      else
%
%
%            % Channel names specified in the header(s) of the data file(s).
%            % Determine the line number of the data file(s) that contain the channel names.
%            % Find the last specified data file.  Open it, and read the channel names.
%
%         NamesLine = cell2mat( ReadVal( ParamFile{1}{11}, 'integer', 1, '' , '' ) );
%
%
%%TODO: Make it so MCrunch uses default name (e.g., "Chan1") if we are getting info from
%%      the data files and NamesLine is set to zero.
%
%         if ( NamesLine == 0 )
%            beep
%            error( '  You must have a line with names (NamesLine) if you want to get information from the data files.' );
%         end % if
%
%         for PLine=1:size( ParamFile{1}, 1 )
%            if ( ~isempty( strfind( ParamFile{1}{PLine}, '==EOF==' ) ) )
%               LastFile = PLine - 1;
%               break
%            end % if
%         end % for PLine
%
%         DataFileName = cell2mat( ReadVal( ParamFile{1}{LastFile}, 'string' , 1, '', '' ) );
%
%         fidData = fopen( DataFileName, 'rt' );
%
%         while ( fidData < 0 )
%            beep;
%            HdlDgl = warndlg( sprintf( 'Please close "%s" if it is open in another program such as Excel.', DataFileName ), 'File Locked!', 'replace' );
%            uiwait( HdlDgl );
%            fidData = fopen( DataFileName, 'rt' );
%         end % while
%
%         HeadLines  = textscan( fidData, '%s', NamesLine, 'delimiter', '\n' );
%         temp       = textscan( HeadLines{1}{NamesLine}, '%s' );
%         NumChans   = size( temp{1}, 1 );
%         NumChansSN = NumChans;
%         ChanNames  = cell( 1, NumChans );
%
%         for Ch=1:NumChans
%            ChanNames{Ch} = [ '$', temp{1}{Ch} ];
%         end % for Ch
%
%      end % if ( NumChans > 0 )
%
%
%         % Add the calculated channel names to the list of channels.
%
%      for Ch=1:NumCChan
%         ChanNames{NumChans+Ch} = [ '$', cell2mat( ReadVal( ParamFile{1}{FirstCC+Ch-1}, 'string' , 1, '' , '' ) ) ];
%      end % for
%
%      TotChans = NumChans + NumCChan;
%
%
%         % Create an cell array of index strings.
%
%      ChanInds = cell( TotChans, 1 );
%
%      for Ch=1:TotChans
%         ChanInds{Ch} = num2str( Ch, '%u' );
%      end % for Ch
%
%
%         % Processing the ParamFile cell array, replace all the "$<ChanName>" strings with
%         % the appropriate indices.
%
%      for Ch=1:TotChans
%         for PLine=1:size( ParamFile{1}, 1 )
%            ParamFile{1}{PLine} = strrep( ParamFile{1}{PLine}, ChanNames{Ch}, ChanInds{Ch} );
%         end % for PLine
%      end % for Ch
%
%   end % if ( StrNames )


      %=================================================================
      % Skip the header.  Read the job options.
      %=================================================================

   PLine   = 4;
   EchoInp = false;
   EchoInp = cell2mat( ReadVal( ParamFile{1}{PLine}, 'logical', 1, 'EchoInp' , 'Echo input to <rootname>.echo as this file is being read.' ) );

   if ( EchoInp )
      UnEc = fopen( [ GetRoot( SettingsFile ), '.echo' ], 'wt' );
      fprintf( UnEc, 'Echoing contents of "%s".\n', SettingsFile );
      for PLine=2:4
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
      end % for
   end % if

   PLine    = 4;
   StrNames = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'logical', 1, 'StrNames', 'Use quoted strings of actual channel names instead of numbers?'    ) );
   OutData  = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'logical', 1, 'OutData' , 'Output modified data array after scaling and calculated channels?' ) );
   RealFmt  = cell2mat( ReadVal( ParamFile{1}{PLine+3}, 'string' , 1, 'RealFmt' , 'Format for outputting floating-point values.'                      ) );
   AggRoot  = cell2mat( ReadVal( ParamFile{1}{PLine+4}, 'string' , 1, 'AggRoot' , 'Root name for aggregate output files.'                             ) );

   StrFmt  = [ '%' , regexp(RealFmt,'\d*', 'ignorecase', 'match', 'once'), 's' ];
   StrFmtL = [ '%-', regexp(RealFmt,'\d*', 'ignorecase', 'match', 'once'), 's' ];
   PLine   = PLine + 5;


      %=================================================================
      % Read the layout of the input data.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   TitleLine     = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'integer', 1, 'TitleLine'    , 'The row with the file title on it.'    ) );
   NamesLine     = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'NamesLine'    , 'The row with the channel names on it.' ) );
   UnitsLine     = cell2mat( ReadVal( ParamFile{1}{PLine+3}, 'integer', 1, 'UnitsLine'    , 'The row with the channel units on it.' ) );
   FirstDataLine = cell2mat( ReadVal( ParamFile{1}{PLine+4}, 'integer', 1, 'FirstDataLine', 'The first row of data.'                ) );
   TotLines      = cell2mat( ReadVal( ParamFile{1}{PLine+5}, 'integer', 1, 'FirstDataLine', 'The first row of data.'                ) );

   if ( NamesLine > 0 )
      FileInfo.AutoNames = true;
      FileInfo.HaveNames = true;
   else
      FileInfo.AutoNames = false;
      FileInfo.HaveNames = false;
   end % if

   if ( UnitsLine > 0 )
      FileInfo.AutoUnits = true;
      FileInfo.HaveUnits = true;
   else
      FileInfo.AutoUnits = false;
      FileInfo.HaveUnits = false;
   end % if

   if ( FileInfo.HaveNames && ( TitleLine >= NamesLine ) )
      beep
      error( '  NamesLine (%d) must be greater than TitleLine (%d) unless NamesLine is zero.', NamesLine, TitleLine );
   end % if

   if ( ( UnitsLine > 0 ) && ( TitleLine >= UnitsLine ) )
      beep
      error( '  UnitsLine (%d) must be greater than TitleLine (%d) unless UnitsLine is zero.', UnitsLine, TitleLine );
   end % if

   if ( ( UnitsLine > 0 ) && ( NamesLine >= UnitsLine ) )
      beep
      error( '  UnitsLine (%d) must be greater than NamesLine (%d) unless UnitsLine is zero.', UnitsLine, NamesLine );
   end % if

   if ( TitleLine >= FirstDataLine )
      beep
      error( '  FirstDataLine (%d) must be greater than TitleLine (%d).', FirstDataLine, TitleLine );
   end % if

   if ( NamesLine >= FirstDataLine )
      beep
      error( '  FirstDataLine (%d) must be greater than NamesLine (%d).', FirstDataLine, NamesLine );
   end % if

   if ( UnitsLine >= FirstDataLine )
      beep
      error( '  FirstDataLine (%d) must be greater than UnitsLine (%d).', FirstDataLine, UnitsLine );
   end % if

   if ( TotLines < 0 )
      beep
      error( '  TotLines (%d) must not be negative.', TotLines );
   elseif ( TotLines > 0 )
      FileInfo.TotLines = uint32( TotLines );
   end % if

%   NumChans = cell2mat( ReadVal( ParamFile{1}{PLine+6}, 'integer', 1, 'NumChans', 'The number of channels in each input file.' ) );

   PLine = PLine + 7;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   if ( UserNames )

      FileInfo.HaveNames = true;
      FileInfo.HaveUnits = true;

      for Chan=1:NumChans

         temp = textscan( ParamFile{1}{PLine+Chan}, '%q %q %f %f', 1 );

         FileInfo.Names  (Chan) = temp{1};
         FileInfo.Units  (Chan) = temp{2};
         FileInfo.Scales (Chan) = temp{3};
         FileInfo.Offsets(Chan) = temp{4};

         if ( EchoInp )
            fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Chan} );
         end % if

      end % for Chan

      PLine = PLine + NumChans + 1;

   else

      PLine = PLine + 1;

   end % if


%   if ( ( NumChans == 0 ) && StrNames )
%      NumChans = NumChansSN;
%   end % if


      %=================================================================
      % Read the filtering information.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the calculated-channels information.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

%   NumCChan = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'integer', 1, 'NumCChan', 'The number calculated channels to generate.'       ) );
%   TotChans = NumChans + NumCChan;
   Seed     = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'Seed'    , 'The integer seed for the random number generator.' ) );
   PLine    = PLine + 3;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   CalcChan = repmat( struct( 'Name','', 'Units','', 'Eqn','' ), 1, double( NumCChan ) );

   for Chan=1:NumCChan
      temp = ReadVal( ParamFile{1}{PLine+Chan}, 'string' , 3, '', '' );
      CalcChan(Chan).Name  = temp{1};
      CalcChan(Chan).Units = temp{2};
      CalcChan(Chan).Eqn   = temp{3};
   end

   PLine = PLine + NumCChan + 1;


      %=================================================================
      % Read the information for plots in general.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   LineWidth     = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'float'  , 1, 'LineWidth',    'The width of curves on the plots.'                                                      ) );
   FigLeftPos    = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'FigLeftPos',   'The number of pixels from the left side of the screen to the left side of the figures.' ) );
   FigBottomPos  = cell2mat( ReadVal( ParamFile{1}{PLine+3}, 'integer', 1, 'FigBottomPos', 'The number of pixels from the bottom of the screen to the bottom of the figures.'       ) );
   FigWidth      = cell2mat( ReadVal( ParamFile{1}{PLine+4}, 'integer', 1, 'FigWidth',     'The horizontal width of the figures in pixels.'                                         ) );
   FigHeight     = cell2mat( ReadVal( ParamFile{1}{PLine+5}, 'integer', 1, 'FigHeight',    'The vertical height of the figures in pixels.'                                          ) );
   FigTitles     = cell2mat( ReadVal( ParamFile{1}{PLine+6}, 'logical', 1, 'FigTitles',    'Add titles to each figure?'                                                             ) );
   SaveFigs      = cell2mat( ReadVal( ParamFile{1}{PLine+7}, 'logical', 1, 'SaveFigs',     'Save the generated figures in files?'                                                   ) );
   ChartPosition = [FigLeftPos, FigBottomPos, FigWidth, FigHeight];

   PLine = PLine + 8;


      %=================================================================
      % Read the information for time-series plots.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   NumTimeFigs = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'integer', 1, 'NumTimeFigs',  'Number of figures for the PDFs.  Each figure will have one or more subplots.'           ) );

   PLine = PLine + 2;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   TimePlots = repmat( struct( 'Name','', 'NRows',0, 'NCols',0, 'Chans',0 ), 1, double( NumTimeFigs ) );

   for Fig=1:NumTimeFigs

      temp = textscan( ParamFile{1}{PLine+Fig}, '%q %f %f', 1 );

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Fig} );
      end % if

      TimePlots(Fig).Name  = temp{1}{1};
      TimePlots(Fig).NRows = temp{2};
      TimePlots(Fig).NCols = temp{3};

      Fmt = [ '%*q %*f %*f', repmat( ' %f', 1, TimePlots(Fig).NRows*TimePlots(Fig).NCols ) ];   % No commas allowed in channel list!

      TimePlots(Fig).Chans = cell2mat( textscan( ParamFile{1}{PLine+Fig}, Fmt, 1 ) );

      if ( size( TimePlots(Fig).Chans, 2 ) ~= TimePlots(Fig).NRows*TimePlots(Fig).NCols )
         beep;
         error( sprintf( [ '\n  For time figure #%d, the number of channels listed is not\n', ...
                           '  equal to the number of rows times the number of columns.\n\n' ], Fig ) );
      end % if

   end % for Fig

   PLine = PLine + NumTimeFigs + 1;


      %=================================================================
      % Read the information for moving averages.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the information for time and wind-speed channels.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   FileInfo.TimeChan = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'integer', 1, 'TimeCol', 'The channel containing time.'    ) );
   FileInfo.WSChan   = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'WS_Col' , 'The primary wind-speed channel.' ) );

   PLine = PLine + 3;


      %=================================================================
      % Read the information for load roses.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the information for azimuth averages.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the information for crosstalk.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the information for peak finding.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the information for statistics and extreme events.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   DoStats      = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'logical', 1, 'DoStats'   , 'Generate statistics of all the channels.'                                         ) );
   WrStatsTxt   = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'logical', 1, 'WrStatsTxt', 'Write a text file of statistics for each input file and the aggregate of all of them.' ) );
   WrStatsXLS   = cell2mat( ReadVal( ParamFile{1}{PLine+3}, 'logical', 1, 'WrStatsXLS', 'Write an Excel file of statistics for each input file and the aggregate of all of them.' ) );
   NumSFChans   = cell2mat( ReadVal( ParamFile{1}{PLine+4}, 'integer', 1, 'NumSFChans', 'Number of channels that will have summary statistics generated for them.'         ) );
   SumStatChans = zeros( NumSFChans );

   if ( NumSFChans > 0 )

      temp = ReadVal( ParamFile{1}{PLine+5}, 'integer', NumSFChans, 'SFChans', 'List of channels that will have summary statistics generated for them.  Must number NumSFChans.' );

      for Chan=1:NumSFChans
         SumStatChans(Chan) = temp{Chan};
      end % for Chan

   else

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+5} );
      end % if

   end % if ( NumSFChans > 0 )

   NumEETables = cell2mat( ReadVal( ParamFile{1}{PLine+6}, 'integer', 1, 'NumEETables', 'Number of tables of extreme events.' ) );
   PLine       = PLine + 7;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   EEvTable = repmat( struct( 'Name','', 'Chans',0, 'InfChans',0 ), 1, double( NumEETables ) );

   if ( NumEETables > 0 )

      for Tab=1:NumEETables

         temp = textscan( ParamFile{1}{PLine+Tab}, '%q %f', 1 );

         if ( EchoInp )
            fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Tab} );
         end % if

         EEvTable(Tab).Name = temp{1}{1};
         NumChans           = temp{2};

         Fmt  = [ '%*q %*f', repmat( ' %f', 1, NumChans ), ' %f' ];   % No commas allowed in channel list!

         EEvTable(Tab).Chans = cell2mat( textscan( ParamFile{1}{PLine+Tab}, Fmt, 1 ) );
         NumInfoChans        = EEvTable(Tab).Chans(NumChans+1);
         EEvTable(Tab).Chans = EEvTable(Tab).Chans(1:NumChans);

         Fmt  = [ '%*q %*f', repmat( ' %*f', 1, NumChans+1 ), repmat( ' %f', 1, NumInfoChans ) ];   % No commas allowed in channel list!

         EEvTable(Tab).InfChans = cell2mat( textscan( ParamFile{1}{PLine+Tab}, Fmt, 1 ) );

      end % for Tab

   end % if ( NumEETables > 0 )

   PLine = PLine + NumEETables + 1;


      %=================================================================
      % Read the information for binning.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   DoBins      = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'logical', 1, 'DoBins'     , 'Bin selected channels?'                                                                      ) );
   NumDepChans = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'NumDepChans', 'The number of dependent channels for binning.'                                               ) );
   UseBinAv    = cell2mat( ReadVal( ParamFile{1}{PLine+3}, 'logical', 1, 'UseBinAv'   , 'When reporting the location of 1-D bins, use the average values instead of the bin centers?' ) );
   PltBins     = cell2mat( ReadVal( ParamFile{1}{PLine+4}, 'logical', 1, 'PltBins'    , 'Plot binned data?'                                                                           ) );
   PltRawData  = cell2mat( ReadVal( ParamFile{1}{PLine+5}, 'logical', 1, 'PltRawData' , 'Plot the raw data on top of the binned data?'                                                ) );
   WrBinsTxt   = cell2mat( ReadVal( ParamFile{1}{PLine+6}, 'logical', 1, 'WrBinsTxt'  , 'Write binning results to a plain-text file?'                                                 ) );
   WrBinsXLS   = cell2mat( ReadVal( ParamFile{1}{PLine+7}, 'logical', 1, 'WrBinsXLS'  , 'Write binning results to an Excel workbook?'                                                 ) );

   if ( DoBins && ~DoStats )
      beep;
      error( '  You must enable generation of statistics (DoStats) if you are going to do binning (DoBins).' );
   end % if

   PLine = PLine + 8;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   Binning = repmat( struct( 'DepChan','', 'NumDims',0, 'IndChan1',0, 'BinWid1',0, 'IndChan2',0, 'BinWid2',0 ), 1, double( NumDepChans ) );

   for Ch=1:NumDepChans

      temp = textscan( ParamFile{1}{PLine+Ch}, '%d %d %d %f', 1 );

      Binning(Ch).DepChan  = temp{1};
      Binning(Ch).NumDims  = temp{2};
      Binning(Ch).IndChan1 = temp{3};
      Binning(Ch).BinWid1  = temp{4};

      if ( Binning(Ch).BinWid1 <= 0 )
         beep;
         error( '  For binning channel #%d, the bin width is not > 0 for the first independent channel.', Ch );
      end % if


      if ( temp{2} == 2 )

         temp = textscan( ParamFile{1}{PLine+Ch}, '%d %d %d %f %d %f', 1 );
         Binning(Ch).IndChan2 = temp{5};
         Binning(Ch).BinWid2  = temp{6};

         if ( Binning(Ch).BinWid2 <= 0 )
            beep;
            error( '  For binning channel #%d, the bin width is not > 0 for the second independent channel.', Ch );
         end % if

      elseif ( temp{2} ~= 1 )
         beep;
         error( [ '  For binning dependent channel #%d, the number of dimensions specified is %d\n', ...
                  '  instead of 1 or 2.' ], Ch, temp{2} );
      end % if

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Ch} );
      end % if

   end % for Fig

   PLine = PLine + NumDepChans + 1;


      %=================================================================
      % Read the information for peak and valley listing.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the information for PDFs.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   DoPDFs      = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'logical', 1, 'DoPDFs'    , 'Generate PDFs of all channels?'       ) );
   PDF         = [];
   NumPDFChans = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'NumPDFChans', 'Number of PDF channels.' ) );

   if ( NumPDFChans > 0 )

      temp = ReadVal( ParamFile{1}{PLine+3}, 'integer', NumPDFChans, 'PDFChans', 'List of PDF channels.  Must number NumPDFChans.' );

      for Ch=1:NumPDFChans
         PDF.Chans(Ch) = temp{Ch};
      end % for Ch

   else

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+3} );
      end % if

   end % if ( NumPDFChans > 0 )

   PDF.NumBins = cell2mat( ReadVal( ParamFile{1}{PLine+4}, 'integer', 1, 'NumBins', 'Number of bins for the PDFs.'         ) );
   PDF.WrTxt   = cell2mat( ReadVal( ParamFile{1}{PLine+5}, 'logical', 1, 'WrTxt'  , 'Write the PDFs to plain-textfiles.'   ) );
   PDF.WrXLS   = cell2mat( ReadVal( ParamFile{1}{PLine+6}, 'logical', 1, 'WrXLS'  , 'Write the PDFs to an Excel workbook.' ) );
   PDF.NumFigs = cell2mat( ReadVal( ParamFile{1}{PLine+7}, 'integer', 1, 'NumFigs', 'Number of figures for the PDFs.'      ) );
   PLine       = PLine + 8;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PDF.Plots = repmat( struct( 'Name','', 'NRows',0, 'NCols',0, 'Chans',0, 'ChanInd',0 ), 1, double( PDF.NumFigs ) );

   for Fig=1:PDF.NumFigs

      temp = textscan( ParamFile{1}{PLine+Fig}, '%q %f %f', 1 );

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Fig} );
      end % if

      PDF.Plots(Fig).Name  = temp{1}{1};
      PDF.Plots(Fig).NRows = temp{2};
      PDF.Plots(Fig).NCols = temp{3};

      Fmt = [ '%*q %*f %*f', repmat( ' %f', 1, PDF.Plots(Fig).NRows*PDF.Plots(Fig).NCols ) ];   % No commas allowed in channel list!

      PDF.Plots(Fig).Chans = cell2mat( textscan( ParamFile{1}{PLine+Fig}, Fmt, 1 ) );

      if ( size( PDF.Plots(Fig).Chans, 2 ) ~= PDF.Plots(Fig).NRows*PDF.Plots(Fig).NCols )
         beep;
         error( [ '\n  For PDF figure #%d, the number of channels listed is not\n', ...
                  '  equal to the number of rows times the number of columns.\n\n' ], Fig );
      end % if


         % Ensure that all the channels selected for plotting were also selected for doing PDFs.
         % Save the indices of the analysis channels for the plot channels.

      NumPlChans             = length( PDF.Plots(Fig).Chans );
      PDF.Plots(Fig).ChanInd = zeros( NumPlChans );

      for PCh=1:NumPlChans

         NotFound = true;

         for ACh=1:NumPDFChans
            if ( PDF.Plots(Fig).Chans(PCh) == PDF.Chans(ACh) )
               PDF.Plots(Fig).ChanInd(PCh) = ACh;
               NotFound = false;
               break
            end % if
         end % for ACh

         if ( NotFound )
            beep;
            error( [ '\n  For PDF figure #%d, you requested a plot of channel #%d, but\n', ...
                     '  that channel was not on for which a PDF was calculated.\n\n' ], Fig, PDF.Plots(Fig).Chans(PCh) );
         end % if

      end % for PCh

   end % for Fig

   PLine = PLine + PDF.NumFigs + 1;




      %=================================================================
      % Read the information for PSDs.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   DoPSDs      = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'logical', 1, 'DoPSDs'     , 'Generate power spectral densities?' ) );
   PSD         = [];
   NumPSDChans = cell2mat( ReadVal( ParamFile{1}{PLine+2}, 'integer', 1, 'NumPSDChans', 'Number of PSD channels.' ) );

   if ( NumPSDChans > 0 )

      temp = ReadVal( ParamFile{1}{PLine+3}, 'integer', NumPSDChans, 'PSDChans', 'List of PSD channels.  Must number NumPSDChans.' );

      for Ch=1:NumPSDChans
         PSD.PSDChans(Ch) = temp{Ch};
      end % for Ch

   else

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+3} );
      end % if

   end % if ( NumPSDChans > 0 )

   PSD.RmvMean    = cell2mat( ReadVal( ParamFile{1}{PLine+04}, 'logical', 1, 'RmvMean'   , 'Remove the mean of the signal(s)?'                                     ) );
   PSD.Detrend    = cell2mat( ReadVal( ParamFile{1}{PLine+05}, 'logical', 1, 'Detrend'   , 'Remove linear trend of the signal(s)?'                                 ) );
   PSD.CosTaper   = cell2mat( ReadVal( ParamFile{1}{PLine+06}, 'logical', 1, 'CosTaper'  , 'Add a cosine taper to the ends of the time series?'                    ) );
   PSD.WindowType = cell2mat( ReadVal( ParamFile{1}{PLine+07}, 'string' , 1, 'WindowType', 'Type of data window.'                                                  ) );
   PSD.IntPSDs    = cell2mat( ReadVal( ParamFile{1}{PLine+08}, 'logical', 1, 'IntPSDs'   , 'Integrate the PSDs before plotting or writing them to a file?'         ) );
   PSD.BinPSDs    = cell2mat( ReadVal( ParamFile{1}{PLine+09}, 'logical', 1, 'BinPSDs'   , 'Bin the PSDs before plotting or writing them to a file?'               ) );
   PSD.BinWidth   = cell2mat( ReadVal( ParamFile{1}{PLine+10}, 'float'  , 1, 'BinWidth'  , 'Width of the PSD bins.'                                                ) );
   PSD.WrXLS      = cell2mat( ReadVal( ParamFile{1}{PLine+11}, 'logical', 1, 'WrXLS'     , 'Write the PSDs to an Excel file?'                                      ) );
   PSD.WrTxt      = cell2mat( ReadVal( ParamFile{1}{PLine+12}, 'logical', 1, 'WrTxt'     , 'Write the PSDs to a text file"'                                        ) );
   NumPSDFigs     = cell2mat( ReadVal( ParamFile{1}{PLine+13}, 'integer', 1, 'NumPSDFigs', 'Number of figures for the PSDs.'                                       ) );

   PLine = PLine + 14;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PSD.Plots = repmat( struct( 'Name','', 'NRows',0, 'NCols',0, 'Chans',0, 'ChanInd',0 ), 1, double( NumPSDFigs ) );

   for Fig=1:NumPSDFigs

      temp = textscan( ParamFile{1}{PLine+Fig}, '%q %f %f', 1 );

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Fig} );
      end % if

      PSD.Plots(Fig).Name  = temp{1}{1};
      PSD.Plots(Fig).NRows = temp{2};
      PSD.Plots(Fig).NCols = temp{3};

      Fmt = [ '%*q %*f %*f', repmat( ' %f', 1, PSD.Plots(Fig).NRows*PSD.Plots(Fig).NCols ) ];   % No commas allowed in channel list!

      PSD.Plots(Fig).Chans = cell2mat( textscan( ParamFile{1}{PLine+Fig}, Fmt, 1 ) );

      NumPlChans = size( PSD.Plots(Fig).Chans, 2 );

      if ( NumPlChans ~= PSD.Plots(Fig).NRows*PSD.Plots(Fig).NCols )
         beep;
         error( [ '\n  For PSD figure #%d, the number of channels listed is not\n', ...
                  '  equal to the number of rows times the number of columns.\n\n' ], Fig );
      end % if


         % Ensure that all the channels selected for plotting were also selected for doing PDFs.
         % Save the indices of the analysis channels for the plot channels.

      PSD.Plots(Fig).ChanInd = zeros( NumPlChans );

      for PCh=1:NumPlChans

         NotFound = true;

         for ACh=1:NumPSDChans
            if ( PSD.Plots(Fig).Chans(PCh) == PSD.PSDChans(ACh) )
               PSD.Plots(Fig).ChanInd(PCh) = ACh;
               NotFound = false;
               break
            end % if
         end % for ACh

         if ( NotFound )
            beep;
            error( [ '\n  For PSD figure #%d, you requested a plot of channel #d, but\n', ...
                     '  that channel was not one for which a PSD was calculated.\n\n' ], Fig, PSD.Plots(Fig).Chans(PCh) );
         end % if

      end % for PCh

   end % for Fig

   PLine = PLine + NumPSDFigs + 1;

   if ( ~DoPSDs )

      PSD.Plots = [];
      PSD      = [];

   end % if ( DoPSDs )


      %=================================================================
      % Read the information for fatigue.
      %=================================================================

   Fatigue = [];

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   DoFatigue          = cell2mat( ReadVal( ParamFile{1}{PLine+01}, 'logical', 1, 'DoFatigue'  , 'Do fatigue analysis.'                                                                               ) );
   NumFatChans        = cell2mat( ReadVal( ParamFile{1}{PLine+02}, 'integer', 1, 'NumFatChans', 'The number of rainflow channels.'                                                                   ) );
   Fatigue.FiltRatio  = cell2mat( ReadVal( ParamFile{1}{PLine+03}, 'float'  , 1, 'FiltRatio'  , 'The fraction of the maximum range of each channel used as a cutoff range for the racetrack filter.' ) );
   Fatigue.RF_Per     = cell2mat( ReadVal( ParamFile{1}{PLine+04}, 'float'  , 1, 'RF_Per'     , 'Number of seconds in the rainflow counting period.'                                                 ) );
   Fatigue.BinCycles  = cell2mat( ReadVal( ParamFile{1}{PLine+05}, 'logical', 1, 'BinCycles'  , 'Bin the rainflow cycles?'                                                                           ) );
   Fatigue.BinMeans   = cell2mat( ReadVal( ParamFile{1}{PLine+06}, 'logical', 1, 'BinMeans'   , 'Bin by cycle means in addition to ranges?'                                                          ) );
   Fatigue.UCMult     = cell2mat( ReadVal( ParamFile{1}{PLine+07}, 'float'  , 1, 'UCMult'     , 'Multiplier for binning unclosed cycles.'                                                            ) );
   Fatigue.DoSimpDELs = cell2mat( ReadVal( ParamFile{1}{PLine+08}, 'logical', 1, 'DoSimpDELs' , 'Compute simple (unweighted) damage-equivalent loads?'                                               ) );
   Fatigue.DoLife     = cell2mat( ReadVal( ParamFile{1}{PLine+09}, 'logical', 1, 'DoLife'     , 'Do lifetime-related calculations?'                                                                  ) );
   Fatigue.RayAverWS  = cell2mat( ReadVal( ParamFile{1}{PLine+10}, 'float'  , 1, 'RayAverWS'  , 'Rayleigh-average wind speed.'                                                                       ) );
   Fatigue.WSmin      = cell2mat( ReadVal( ParamFile{1}{PLine+11}, 'float'  , 1, 'WSmin'      , 'Starting value for the wind-speed bins for the Rayleigh distribution.'                              ) );
   Fatigue.WSdel      = cell2mat( ReadVal( ParamFile{1}{PLine+12}, 'float'  , 1, 'WSdel'      , 'Delta value for the wind-speed bins for the Rayleigh distribution.'                                 ) );
   Fatigue.CumFatigue = cell2mat( ReadVal( ParamFile{1}{PLine+13}, 'logical', 1, 'CumFatigue' , 'Generate cycle data as cumulative cycles?'                                                          ) );
   Fatigue.WrRFTxt    = cell2mat( ReadVal( ParamFile{1}{PLine+14}, 'logical', 1, 'WrRFTXT'    , 'Write rainflow data to plain-text files?'                                                           ) );
   Fatigue.WrRFXLS    = cell2mat( ReadVal( ParamFile{1}{PLine+15}, 'logical', 1, 'WrRFXLS'    , 'Write rainflow data to an Excel workbook?'                                                          ) );
   Fatigue.WrDELsTxt  = cell2mat( ReadVal( ParamFile{1}{PLine+16}, 'logical', 1, 'WrDELsTXT'  , 'Write DELs to plain-text files?'                                                                    ) );
   Fatigue.WrDELsXLS  = cell2mat( ReadVal( ParamFile{1}{PLine+17}, 'logical', 1, 'WrDELsXLS'  , 'Write DELs to an Excel workbook?'                                                                   ) );
   Fatigue.WrLifeTxt  = cell2mat( ReadVal( ParamFile{1}{PLine+18}, 'logical', 1, 'WrLifeTXT'  , 'Write lifetime results to plain-text files?'                                                        ) );
   Fatigue.WrLifeXLS  = cell2mat( ReadVal( ParamFile{1}{PLine+19}, 'logical', 1, 'WrLifeXLS'  , 'Write lifetime results to an Excel workbook?'                                                       ) );
   Fatigue.PltBinCyc  = cell2mat( ReadVal( ParamFile{1}{PLine+20}, 'logical', 1, 'PltBinCyc'  , 'Plot binned rainflow cycles?'                                                                       ) );
   Fatigue.PltProbExc = cell2mat( ReadVal( ParamFile{1}{PLine+21}, 'logical', 1, 'PltProbExc' , 'Plot probability of exceedance?'                                                                    ) );
   Fatigue.PltCumCyc  = cell2mat( ReadVal( ParamFile{1}{PLine+22}, 'logical', 1, 'PltCumCyc'  , 'Plot cumulative rainflow cycles?'                                                                   ) );
   Fatigue.PltRngMean = cell2mat( ReadVal( ParamFile{1}{PLine+23}, 'logical', 1, 'PltRngMean' , 'Plot 3D range and mean of binned rainflow cycles?'                                                  ) );
   Fatigue.TblDELs    = cell2mat( ReadVal( ParamFile{1}{PLine+24}, 'logical', 1, 'TblDELs'    , 'Generate a table of damage-equivalent loads?'                                                       ) );

   PLine = PLine + 25;

   if ( DoFatigue )

      if ( ~DoStats )
         beep;
         error( '  To do fatigue calculations, you must enable calculation of statistics (DoStats).' );
      end % if

      Fatigue.CumFatigue = Fatigue.WrRFTxt | Fatigue.WrRFXLS | Fatigue.PltCumCyc | Fatigue.PltProbExc;
      Fatigue.DoFatPlots = Fatigue.PltBinCyc | Fatigue.PltProbExc | Fatigue.PltCumCyc | Fatigue.PltRngMean | Fatigue.TblDELs;

      if ( ~Fatigue.BinCycles && Fatigue.PltBinCyc )
         beep;
         error( '  For fatigue, you must enable binning of cycles (BinCycles) if you want to plot them (PltBinCyc).' );
      end % if

      if ( ~( Fatigue.BinMeans && Fatigue.BinCycles ) && Fatigue.PltRngMean )
         beep;
         error( '  For fatigue, you must enable binning of cycles (BinCycles) and binning of cycle means (BinMeans) if you want to plot them (PltRngMean).' );
      end % if

      if ( Fatigue.BinMeans && Fatigue.DoLife )
         beep;
         error( '  For fatigue, do not enable binning of cycle means (BinMeans) if you want to do fatigue-life calculations (DoLife).' );
      end % if

      if ( ~Fatigue.BinCycles && Fatigue.DoLife )
         beep;
         error( '  For fatigue, you must enable binning of cycles (BinCycles) if you want to do fatigue-life calculations (DoLife).' );
      end % if

      if ( Fatigue.DoLife && ( Fatigue.RayAverWS <= 0 ) )
         beep;
         error( '  For fatigue, the Rayleigh-average wind speed (RayAverWS) must be greater than zero.' );
      end % if

      if ( Fatigue.DoLife && ( Fatigue.WSdel <= 0 ) )
         beep;
         error( '  For fatigue, the delta value for the wind-speed bins for the Rayleigh distribution (WSdel) must be greater than zero.' );
      end % if

      if ( Fatigue.DoLife && ( FileInfo.WSChan == 0 ) )
         beep;
         error( '  For fatigue, you cannot do lifetime calculations without specifying the wind-speed channel (WSChan).' );
      end % if

      if ( Fatigue.DoLife && ~( Fatigue.WrLifeTxt || Fatigue.WrLifeXLS ) )
         beep;
         error( '  For fatigue, you are doing lifetime calculations, but you are not asking for output (WrLifeTxt or WrLifeXLS).' );
      end % if

   end % if

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   if ( DoFatigue )

      for Ch=1:NumFatChans


            % First, see how many S/N Slopes were entered.  That will determine the format.  Then, do the real read.

         temp = textscan( ParamFile{1}{PLine+Ch}, '%d %f', 1 );

         if ( EchoInp )
            fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Ch} );
         end % if

         Fmt = [ '%d %f', repmat( ' %f', 1, temp{2} ), ' %f %s %f' ];

         temp = textscan( ParamFile{1}{PLine+Ch}, Fmt, 1 );

         Fatigue.ChanInfo(Ch).Chan    = temp{1};

         if ( Fatigue.DoLife && ( ( Fatigue.ChanInfo(Ch).Chan <= 0 ) || ( Fatigue.ChanInfo(Ch).Chan > TotChans ) ) )
            beep;
               error( '  For fatigue channel #%d, the channel number must be between 1 and %d (inclusive).', Ch, TotChans );
         end % if

         Fatigue.ChanInfo(Ch).NSlopes = temp{2};

%TODO: Fix CompFatigue.m to handle more than one slope.
         if (  Fatigue.ChanInfo(Ch).NSlopes ~= 1 )
            beep;
            error( '  For fatigue channel #%d, the number of S/N slopes (NSlopes) must be 1.  This is a temporary restriction.', Ch );
         end % if

         if ( Fatigue.ChanInfo(Ch).NSlopes <= 0 )
            beep;
            error( '  For fatigue channel #%d, the number of S/N slopes (NSlopes) must be greater than zero.', Ch );
         end % if

         for Slope=1:Fatigue.ChanInfo(Ch).NSlopes
            Fatigue.ChanInfo(Ch).SNslopes(Slope) = temp{Slope+2};
         end % for Slope

         if ( Fatigue.BinCycles )
            Fatigue.ChanInfo(Ch).BinWidth = temp{Fatigue.ChanInfo(Ch).NSlopes+3};
         end % if

         Fatigue.ChanInfo(Ch).TypeLMF = temp{Fatigue.ChanInfo(Ch).NSlopes+4}{1};
         Fatigue.ChanInfo(Ch).LMF     = sscanf( Fatigue.ChanInfo(Ch).TypeLMF, '%f' );

         if ( isnumeric( Fatigue.ChanInfo(Ch).LMF ) )

            Fatigue.ChanInfo(Ch).TypeLMF = 'value';

         elseif ( DoLife )

%TODO: Fix CompFatigue.m to compute the aggregate and weighted means.
            beep;
            error( '  For fatigue channel #%d, the type of fixed load mean (TypeLMF) must be a value.', Ch );

            if ( ~strcmpi( Fatigue.ChanInfo(Ch).TypeLMF, 'AM' )  && ~strcmpi( Fatigue.ChanInfo(Ch).TypeLMF, 'WM' ) )
               beep;
               error( '  For fatigue channel #%d, the type of fixed load mean (TypeLMF) must be either a value, "AM", or "WM".', Ch );
            end % if

            Fatigue.ChanInfo(Ch).LMF = [];

         end % if

         Fatigue.ChanInfo(Ch).LUlt = temp{Fatigue.ChanInfo(Ch).NSlopes+5};

         if ( Fatigue.DoLife && ( Fatigue.ChanInfo(Ch).LUlt <= 0 ) )
            beep;
            error( '  For fatigue channel #%d, the ultimate load (LUlt) must be > 0.', Ch );
         end % if

      end % for Ch

   end % if
%error('debugging...');

   PLine = PLine + NumFatChans + 1;

   NumFatFigs = cell2mat( ReadVal( ParamFile{1}{PLine}, 'integer', 1, 'NumFatFigs', 'Number of figures for the rainflow analysis.' ) );

   temp  = [];
   PLine = PLine + 1;

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   for Fig=1:NumFatFigs

      temp = textscan( ParamFile{1}{PLine+Fig}, '%q %f %f', 1 );

      if ( EchoInp )
         fprintf( UnEc, '%s\n', ParamFile{1}{PLine+Fig} );
      end % if

      Fatigue.Plots(Fig).Name  = temp{1}{1};
      Fatigue.Plots(Fig).NRows = temp{2};
      Fatigue.Plots(Fig).NCols = temp{3};

      Fmt = [ '%*q %*f %*f', repmat( ' %f', 1, Fatigue.Plots(Fig).NRows*Fatigue.Plots(Fig).NCols ) ];   % No commas allowed in channel list!

      Fatigue.Plots(Fig).Chans = cell2mat( textscan( ParamFile{1}{PLine+Fig}, Fmt, 1 ) );
      NumFigChans              = size( Fatigue.Plots(Fig).Chans, 2 );

      if ( NumFigChans ~= Fatigue.Plots(Fig).NRows*Fatigue.Plots(Fig).NCols )
         beep;
         error( [ '\n  For fatigue figure #%d, the number of channels listed is not\n', ...
                  '  equal to the number of rows times the number of columns.\n\n' ], Fig );
      end % if


         % Map these channel names into the ones specified for fatigue analysis and check for validity.

      Fatigue.Plots(Fig).FatChan = zeros( NumFigChans, 1 );

      for SP=1:NumFigChans

         NotFound = true;

         for Ch=1:NumFatChans
            if ( Fatigue.Plots(Fig).Chans(SP) == Fatigue.ChanInfo(Ch).Chan )
               Fatigue.Plots(Fig).FatChan(SP) = Ch;
               NotFound = false;
               break
            end % if
         end % for Ch

         if ( NotFound )
            beep;
            error( [ '\n  For fatigue figure #%d, subplot #d, the channel specified (%d) is not\n', ...
                     '  in the list of fatigue channels.\n\n' ], Fig, SP, Fatigue.Plots(Fig).Chans(SP) );
         end % if

      end % for SP

   end % for Fig

   PLine = PLine + NumFatFigs + 1;


      %=================================================================
      % Read the information for statistical extrapolation.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   PLine = PLine + 1;


      %=================================================================
      % Read the list of input files.
      %=================================================================

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine} );
   end % if

   NumFiles = cell2mat( ReadVal( ParamFile{1}{PLine+1}, 'integer', 1, 'NumFiles', 'The number of input files to read.' ) );
   FileList = cell( NumFiles, 1 );

   PLine = PLine + 1;

   for File=1:NumFiles
      FileList{File,1} = cell2mat( ReadVal( ParamFile{1}{PLine+File}, 'string' , 1, '', '' ) );
   end % for File

   if ( EchoInp )
      fprintf( UnEc, '%s\n', ParamFile{1}{PLine+NumFiles+1} );
      fclose( UnEc );
   end % if

   fclose( UnPa );

   if ( DoFatigue && Fatigue.PltRngMean && NumFiles > 1 )
      beep;
      error( '  You cannot generate Range/Mean fatigue plots (PltRngMean) with multiple files.' );
   end % if

   if ( DoFatigue && Fatigue.DoLife && NumFiles == 1 )
      beep;
      error( '  It is not meaningful to do fatigue-life calculations with only a single file.' );
   end % if

   return

% end script ReadSettings
