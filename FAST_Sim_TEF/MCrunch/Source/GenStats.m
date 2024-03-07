function GenStats( SumStatChans, WrStatsTxt, WrStatsXLS, SettingsFile )
% Generate statistics of data.
%
% This function calculates the following statistics for data
% stored in the FileInfo data structure:
%     Minimum plus corresponding index
%     Mean
%     Maximum plus corresponding index
%     Standard Deviation
%     Skewness
%     Range (Maximum-Minimum)
%
% It process all datasets in the structure and adds the statistics
% to the original data structure.
%
% Syntax is:  GenStats( SumStatChans, WrStatsTxt, WrStatsXLS )
%
%     where:
%        SumStatChans:  A double array of channel numbers for which summary
%                       statistics are desired.
%        WrStatsTxt:    A boolean scalar that indicates if the user wants the
%                       statistics written to a plain text file.
%        WrStatsXLS:    A boolean scalar that indicates if the user wants the
%                       statistics written to an Excel workbook.
%
% Example:
%     GenStats( [ 1, 5, 9 ], false, true )
%
% See also DelFile, DelSheet1, GetRoot, MCrunch, ReadSettings

   global AggRoot FileInfo ProgName RealFmt StrFmt

   NumCols = size( FileInfo.Names, 2 );

   fprintf( '\n' );


      % Initialize and set the class for the indices.

   NumFiles = size( FileInfo.FileName, 1 );
   NumChans = size( FileInfo.Names   , 2 );

   FileInfo.Stats.MinInds = zeros( NumFiles, NumChans, 'uint32' );
   FileInfo.Stats.MaxInds = zeros( NumFiles, NumChans, 'uint32' );


      % No sense doing aggregate statistics if only one file is being processed.

   if ( NumFiles > 1 )
      FileInfo.Stats.AggMinInds = zeros( 1, NumChans, 'uint32' );
      FileInfo.Stats.AggMaxInds = zeros( 1, NumChans, 'uint32' );

      FirstFile = 0;
   else
      FirstFile = 1;
   end


      % Process the aggregate if appropriate and individual data sets in the structure.

   for File=FirstFile:NumFiles


         % Compute statistics.

      CompStats( File );


         % Create plain-text statistics files if requested.

      if ( WrStatsTxt )
         WrTxt( File );
      end

   end


      % Create an Excel workbook with one sheet for the aggregate and one for each file if requested.

   if ( WrStatsXLS )
      WrXLS;
   end


      % Generate summary statistics of selected files.

   for C=1:size( SumStatChans, 2 );
      GenSumStats( SumStatChans(C) );
   end % for

   return
%===============================================================================
   function CompStats( File )

      if ( File == 0 )                                         % Aggregate statistics.

         RowRange = 1:FileInfo.TotLines;


            % Generate statistics.

         fprintf( '  Generating aggregate statistics.\n' );

         [ FileInfo.Stats.AggMinima, FileInfo.Stats.AggMinInds ] = min( FileInfo.Time(RowRange,:) );
         [ FileInfo.Stats.AggMaxima, FileInfo.Stats.AggMaxInds ] = max( FileInfo.Time(RowRange,:) );

         FileInfo.Stats.AggMeans   = mean    ( FileInfo.Time(RowRange,:) );
         FileInfo.Stats.AggStdDevs = std     ( FileInfo.Time(RowRange,:) );
         FileInfo.Stats.AggSkews   = skewness( FileInfo.Time(RowRange,:) );

         FileInfo.Stats.AggRange = FileInfo.Stats.AggMaxima - FileInfo.Stats.AggMinima;


            % Check for constant data.  Correct skewness if it is.

         for Chan=1:size( FileInfo.Names, 2 )

            if ( FileInfo.Stats.AggRange(Chan) <= realmin )
               FileInfo.Stats.AggSkews(Chan) = 0;
            end % if

         end % for

      else                                                     % Individual-file statistics.

         RowRange = FileInfo.StartLine(File) : ( FileInfo.StartLine(File) + FileInfo.NumLines(File) - 1 );


            % Generate statistics.

         fprintf( '  Generating statistics for "%s".\n', FileInfo.FileName{File} );

         [ FileInfo.Stats.Minima(File,:), FileInfo.Stats.MinInds(File,:) ] = min( FileInfo.Time(RowRange,:) );
         [ FileInfo.Stats.Maxima(File,:), FileInfo.Stats.MaxInds(File,:) ] = max( FileInfo.Time(RowRange,:) );

         FileInfo.Stats.Means  (File,:) = mean    ( FileInfo.Time(RowRange,:) );
         FileInfo.Stats.StdDevs(File,:) = std     ( FileInfo.Time(RowRange,:) );
         FileInfo.Stats.Skews  (File,:) = skewness( FileInfo.Time(RowRange,:) );

         FileInfo.Stats.Range(File,:) = FileInfo.Stats.Maxima(File,:) - FileInfo.Stats.Minima(File,:);


            % Check for constant data.  Correct skewness if it is.

         for Chan=1:size( FileInfo.Names, 2 )

            if ( FileInfo.Stats.Range(File,Chan) <= realmin )
               FileInfo.Stats.Skews(File,Chan) = 0;
            end % if

         end % for

      end % if

      return

   end % function CompStats
%===============================================================================
   function GenSumStats( Chan )


         % Find the longest input-file name.

      MaxNameLen = size( FileInfo.FileName{1}, 2 );

      for File=2:NumFiles
         if ( size( FileInfo.FileName{File}, 2 ) > MaxNameLen )
            MaxNameLen = size( FileInfo.FileName{File}, 2 );
         end % if
      end % for


         % Open summary file and write header.

      DateTime = clock;

      fid = fopen( [ FileInfo.Names{Chan}, '.sums' ], 'wt' );

      if ( fid < 0 )
         beep
         error( sprintf( '  Could not open "%s.sums" for writing.', FileInfo.Names{Chan} ) );
      end

      if ( FileInfo.HaveUnits )
         fprintf( fid, '\nThese summary statistics for %s%s were generated by %s on %s at %02d:%02d:%02d.\n\n', ...
            FileInfo.Names{Chan}, FileInfo.Units{Chan}, ProgName, date, uint8( DateTime(4:6) ) );
      else
         fprintf( fid, '\nThese summary statistics for %s were generated by %s on %s at %02d:%02d:%02d.\n\n', ...
            FileInfo.Names{Chan}, ProgName, date, uint8( DateTime(4:6) ) );
      end % if

      fprintf( fid, [ 'File Name%s', repmat( [ ' ', StrFmt ], 1, 6 ), '\n' ], repmat( ' ', 1, MaxNameLen-8 ), 'Minimum', 'Mean', 'Maximum', 'StdDev', 'Skewness', 'Range' );

         % Output the statistics of this channel for each input file.

      Fmt = [ '%s %s', repmat( [ ' ', RealFmt ], 1, 6 ), '\n' ];

      for File=1:NumFiles
         fprintf( fid, Fmt, ...
            FileInfo.FileName{File}, repmat( ' ', 1, MaxNameLen-size( FileInfo.FileName{File}, 2 ) ), ...
            FileInfo.Stats.Minima (File,Chan), FileInfo.Stats.Means(File,Chan), FileInfo.Stats.Maxima(File,Chan), ...
            FileInfo.Stats.StdDevs(File,Chan), FileInfo.Stats.Skews(File,Chan), FileInfo.Stats.Range (File,Chan) );
      end % for

      fclose( fid );

      return

   end % function GenSumStats
%===============================================================================
   function WrTxt( File )

      if ( File == 0 )
         fid = fopen( [ AggRoot, '.stat' ], 'wt' );
         if ( fid < 0 )
            beep
            error( sprintf( '  Could not open "%s.st" for writing.', AggRoot ) );
         end
      else
         fid = fopen( [ GetRoot( FileInfo.FileName{File} ), '.stat' ], 'wt' );
         if ( fid < 0 )
            beep
            error( '  Could not open "%s.stat" for writing.', GetRoot( FileInfo.FileName{File} ) );
         end
      end % if

      DateTime = clock;

      fprintf( fid, '\nThese statistics were generated by %s on %s at %02d:%02d:%02d.\n', ProgName, date, uint8( DateTime(4:6) ) );

      if ( File == 0 )
         fprintf( fid, '\nThe analysis was based upon %d rows from an aggregate of %d files.\n\n', FileInfo.TotLines, NumFiles );
      else
         fprintf( fid, '\nThe analysis was based upon %d rows.\n', FileInfo.NumLines(File) );
         if ( isfield( FileInfo, 'Title' ) )
            fprintf( fid, '\n%s\n\n', FileInfo.Title{File} );
         end % if
      end % if

      fprintf( fid, [ 'Parameter  Units     ', repmat( [ ' ', StrFmt ], 1, 6 ), '\n' ], 'Minimum', 'Mean', 'Maximum', 'StdDev', 'Skewness', 'Range' );

      if ( FileInfo.HaveUnits )
         Fmt = [ '%-10s %-10s', repmat( [ ' ', RealFmt ], 1, 6 ), '\n' ];
      else
         Fmt = [ '%-10s', repmat( [ ' ', RealFmt ], 1, 6 ), '\n' ];
      end % if

      for Col=1:NumCols

         if ( File == 0 )
            if ( FileInfo.HaveUnits )
               fprintf( fid, Fmt, ...
                  FileInfo.Names{Col}, FileInfo.Units{Col}, ...
                  FileInfo.Stats.AggMinima (Col), FileInfo.Stats.AggMeans(Col), FileInfo.Stats.AggMaxima(Col), ...
                  FileInfo.Stats.AggStdDevs(Col), FileInfo.Stats.AggSkews(Col), FileInfo.Stats.AggRange (Col) );
            else
               fprintf( fid, Fmt, ...
                  FileInfo.Names{Col}, ...
                  FileInfo.Stats.AggMinima (Col), FileInfo.Stats.AggMeans(Col), FileInfo.Stats.AggMaxima(Col), ...
                  FileInfo.Stats.AggStdDevs(Col), FileInfo.Stats.AggSkews(Col), FileInfo.Stats.AggRange (Col) );
            end % if
         else
            if ( FileInfo.HaveUnits )
               fprintf( fid, Fmt, ...
                  FileInfo.Names{Col}, FileInfo.Units{Col}, ...
                  FileInfo.Stats.Minima (File,Col), FileInfo.Stats.Means(File,Col), FileInfo.Stats.Maxima(File,Col), ...
                  FileInfo.Stats.StdDevs(File,Col), FileInfo.Stats.Skews(File,Col), FileInfo.Stats.Range (File,Col) );
            else
               fprintf( fid, Fmt, ...
                  FileInfo.Names{Col}, ...
                  FileInfo.Stats.Minima (File,Col), FileInfo.Stats.Means(File,Col), FileInfo.Stats.Maxima(File,Col), ...
                  FileInfo.Stats.StdDevs(File,Col), FileInfo.Stats.Skews(File,Col), FileInfo.Stats.Range (File,Col) );
            end % if
         end % if

      end % for

      fclose( fid );

      return

   end % function WrTxt( File )
   %===============================================================================
   function WrXLS
   % Write the statistics to an Excel file.


       % Set up the name of the Excel file.  Delete the file if it already exists

      XLSfile = [ GetRoot( SettingsFile ), '_Stats.xls' ];

      fprintf( '  Writing binned data to "%s".\n', XLSfile );

      DelFile( XLSfile );


         % Turn off warnings regarding adding sheets to the workbook.

      warning off MATLAB:xlswrite:AddSheet


         % Get the date and time.

      DateTime = clock;
      Date     = date;


         % Create a sheet for the aggregate statistics if there was more than one input file.

      Info = cell( NumChans+5, 8 );

      if ( NumFiles > 1 )

         Sheet = 'Aggregate';

         fprintf( '    Sheet: "%s"\n', Sheet );

         Info{1}       = sprintf( 'These aggregate statistics were generated by %s on %s at %02d:%02d:%02d.', ProgName, Date, uint8( DateTime(4:6) ) );
         Info{3}       = sprintf( 'The analysis was based upon %d rows from an aggregate of %d files.',  FileInfo.TotLines, NumFiles );

         if ( FileInfo.HaveUnits )
            Info(5,:)     = { 'Parameter', 'Units', 'Minimum', 'Mean', 'Maximum', 'StdDev', 'Skewness', 'Range' };
            Info(6:end,1) = FileInfo.Names';
            Info(6:end,2) = FileInfo.Units';
            Info(6:end,3) = mat2cell( FileInfo.Stats.AggMinima' , repmat(1,NumChans,1), 1 );
            Info(6:end,4) = mat2cell( FileInfo.Stats.AggMeans'  , repmat(1,NumChans,1), 1 );
            Info(6:end,5) = mat2cell( FileInfo.Stats.AggMaxima' , repmat(1,NumChans,1), 1 );
            Info(6:end,6) = mat2cell( FileInfo.Stats.AggStdDevs', repmat(1,NumChans,1), 1 );
            Info(6:end,7) = mat2cell( FileInfo.Stats.AggSkews'  , repmat(1,NumChans,1), 1 );
            Info(6:end,8) = mat2cell( FileInfo.Stats.AggRange'  , repmat(1,NumChans,1), 1 );
         else
            Info(5,:)     = { 'Parameter', 'Units', 'Minimum', 'Mean', 'Maximum', 'StdDev', 'Skewness', 'Range' };
            Info(6:end,1) = FileInfo.Names';
            Info(6:end,2) = mat2cell( FileInfo.Stats.AggMinima' , repmat(1,NumChans,1), 1 );
            Info(6:end,3) = mat2cell( FileInfo.Stats.AggMeans'  , repmat(1,NumChans,1), 1 );
            Info(6:end,4) = mat2cell( FileInfo.Stats.AggMaxima' , repmat(1,NumChans,1), 1 );
            Info(6:end,5) = mat2cell( FileInfo.Stats.AggStdDevs', repmat(1,NumChans,1), 1 );
            Info(6:end,6) = mat2cell( FileInfo.Stats.AggSkews'  , repmat(1,NumChans,1), 1 );
            Info(6:end,7) = mat2cell( FileInfo.Stats.AggRange'  , repmat(1,NumChans,1), 1 );
         end % if

         xlswrite( XLSfile, Info, Sheet, 'A2' );

      end % if


         % Add one sheet for each data file.

      for File=1:NumFiles

         Sheet = GetRoot( FileInfo.FileName{File} );

         fprintf( '    Sheet: "%s"\n', Sheet );

         Info{1}       = sprintf( 'These statistics for "%s" were generated by %s on %s at %02d:%02d:%02d.', FileInfo.FileName{File}, ProgName, Date, uint8( DateTime(4:6) ) );
         Info{3}       = sprintf( 'The analysis was based upon %d rows.',  FileInfo.NumLines(File), NumFiles );

         if ( FileInfo.HaveUnits )
            Info(5,:)     = { 'Parameter', 'Units', 'Minimum', 'Mean', 'Maximum', 'StdDev', 'Skewness', 'Range' };
            Info(6:end,1) = FileInfo.Names';
            Info(6:end,2) = FileInfo.Units';
            Info(6:end,3) = mat2cell( FileInfo.Stats.Minima(File,:)' , repmat(1,NumChans,1), 1 );
            Info(6:end,4) = mat2cell( FileInfo.Stats.Means(File,:)'  , repmat(1,NumChans,1), 1 );
            Info(6:end,5) = mat2cell( FileInfo.Stats.Maxima(File,:)' , repmat(1,NumChans,1), 1 );
            Info(6:end,6) = mat2cell( FileInfo.Stats.StdDevs(File,:)', repmat(1,NumChans,1), 1 );
            Info(6:end,7) = mat2cell( FileInfo.Stats.Skews(File,:)'  , repmat(1,NumChans,1), 1 );
            Info(6:end,8) = mat2cell( FileInfo.Stats.Range(File,:)'  , repmat(1,NumChans,1), 1 );
         else
            Info(5,:)     = { 'Parameter', 'Minimum', 'Mean', 'Maximum', 'StdDev', 'Skewness', 'Range' };
            Info(6:end,1) = FileInfo.Names';
            Info(6:end,2) = mat2cell( FileInfo.Stats.Minima(File,:)' , repmat(1,NumChans,1), 1 );
            Info(6:end,3) = mat2cell( FileInfo.Stats.Means(File,:)'  , repmat(1,NumChans,1), 1 );
            Info(6:end,4) = mat2cell( FileInfo.Stats.Maxima(File,:)' , repmat(1,NumChans,1), 1 );
            Info(6:end,5) = mat2cell( FileInfo.Stats.StdDevs(File,:)', repmat(1,NumChans,1), 1 );
            Info(6:end,6) = mat2cell( FileInfo.Stats.Skews(File,:)'  , repmat(1,NumChans,1), 1 );
            Info(6:end,7) = mat2cell( FileInfo.Stats.Range(File,:)'  , repmat(1,NumChans,1), 1 );
         end % if

         xlswrite( XLSfile, Info, Sheet, 'A2' );

      end % for File


         % Leave the Aggregate sheet in the workbook selected if there was more than one file.
  %MLB: If only it didn't take so long to do this...
  %    if ( NumFiles > 1 )
  %       xlswrite( XLSfile, ' ', 'Aggregate', 'A1' );
  %    end % if


         % Delete the blank sheet, "Sheet1".

      DelSheet1( XLSfile );


      fprintf( '  Done.\n' );
      return

   end % function WrXLS
%===============================================================================

end % function GenStats
