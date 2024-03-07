function ReadManyFiles( FileList, TitleLine, NamesLine, UnitsLine, FirstDataLine, CalcChan )
% Read one of more data files into the FileInfo structure.
%
% Notes:
%
%     All files must have the same number of columns.
%     Titles, names, and units must all be before the data and in that order.
%     Set TitleLine, NamesLine, and/or UnitsLine to zero if they do not exist.
%
%BUG: This routine assumes that there are at least 50 lines of data in each file.
%
% The created global structure has the following format:
%
%     FileInfo.TimeChan  - integer
%             .WSChan    - integer
%             .TotLines  - integer
%             .Title     - cell array with NumFiles strings
%             .StartLine - array with NumFiles integers
%             .NumLines  - array with NumFiles integers
%             .Names     - cell array with NumCols+NumCChan strings
%             .Units     - cell array with NumCols+NumCChan strings
%             .FileName  - cell array with NumFiles by 1 strings
%             .Time      - matrix with TotLines by NumCols+NumCChan single-precision data
%             .Stats     - array with 1 by NumCols doubles
%             .Scales    - array with 1 by NumCols doubles
%             .Offsets   - array with 1 by NumCols doubles
%
% Syntax: ReadManyFiles( FileList, TitleLine, NamesLine, UnitsLine, FirstDataLine, CalcChan )
%
%     where:
%        FileList       - A cell array containing a list of file names.
%        TitleLine      - A double scalar telling the number of the line that contains the
%                         file's descriptive title line.  Set to zero if there is none.
%        NamesLine      - A double scalar telling the number of the line that contains the
%                         channel names.  Set to zero if there is none.
%        UnitsLine      - A double scalar telling the number of the line that contains the
%                         channel units.  Set to zero if there is none.
%        FirstDataLine  - A double scalar telling the number of the line that contains the
%                         file's first line or data.
%        CalcChan       - A structure array containing information for generating calculated
%                         channels.  It must have the following format (all are strings):
%                              CalcChan(Chan).Name  - The calculated channel's name.
%                              CalcChan(Chan).Units - The calculated channel's units.
%                              CalcChan(Chan).Eqn   - The calculated channel's equation.
%
% Example:
%     ReadManyFiles( FileList, 2, 4, 5, 6, CalcChan )
%
% See also MCrunch, ReadSettings


   global FileInfo


      % Estimate the number of lines in all the files.

   NumFiles = int16( size( FileList, 1 ) );

   if ( exist( 'FileInfo.TotLines' ) )
      AutoLength = false;
   else
      AutoLength = true;
      FileInfo.TotLines = uint32( 0 );
   end % if

   LinePad   = 1.03;
   SampLines = uint32( 10 );


      % Preallocate some branches of the FileInfo structure.

   FileInfo.Title     = cell( NumFiles, 1 );
   FileInfo.StartLine = zeros( NumFiles, 1 );
   FileInfo.NumLines  = zeros( NumFiles, 1 );


      % How many calculated channels do we have?

   NumCC = size( CalcChan, 2 );


      % If the user did not specify the total length of all files, estimate the total number of lines.

   if ( AutoLength )

      for File=1:NumFiles

         Info = dir( FileList{File} );

         if ( size( Info, 1 ) == 0 )
            beep
            error( '  Could not open "%s" for reading.', FileList{File} );
         end

         FileSize = Info.bytes;

         fid = fopen( FileList{File}, 'rt' );

         if ( fid < 0 )
            beep
            error( '  Could not open "%s" for reading.', FileList{File} );
         end


            % Skip header lines.  Read first SampLines data lines.  Get total number of characters.
            % Estimate total number of lines in file and multiply by LinePad.

         HeadLines = textscan( fid, '%s', FirstDataLine-1, 'delimiter', '\n' );
         HeadSize  = uint32( 0 );

         for L=1:FirstDataLine-1
            HeadSize = HeadSize + size( HeadLines{1,1}{L}, 2 );
         end

         DataLines = textscan( fid, '%s', SampLines, 'delimiter', '\n' );

         if ( size( DataLines{1,1}, 1 ) > SampLines )

            SampSize  = uint32( 0 );

            for L=1:SampLines
               SampSize = SampSize + size( DataLines{1,1}{L}, 2 );
            end

            FileInfo.TotLines = FileInfo.TotLines + LinePad*SampLines*( FileSize - HeadSize )/SampSize;

         else

            FileInfo.TotLines = FileInfo.TotLines + size( DataLines{1,1}, 1 );

         end % if

         fclose( fid );

      end

   end % if ( AutoLength )


      % Get the channel names and units from the last header.

   if ( FileInfo.AutoNames )
      CellNames      = textscan( HeadLines{1}{NamesLine}, '%s' );
      FileInfo.Names = { CellNames{1}{:} };
   end % if

   if ( ( NumCC > 0 ) && FileInfo.HaveNames )
      FileInfo.Names = { FileInfo.Names{:}, CalcChan(:).Name };
   end % if ( NumCC > 0 )

   NumCols = size( FileInfo.Names, 2 );
   NumIC   = NumCols - NumCC;

   if ( FileInfo.AutoUnits )
      CellUnits      = textscan( HeadLines{1}{UnitsLine}, '%s', NumCols );
      FileInfo.Units = { CellUnits{1}{:} };
   end % if ( FileInfo.HaveUnits )

   if ( ( NumCC > 0 ) && FileInfo.HaveUnits )
      FileInfo.Units = { FileInfo.Units{:}, CalcChan(:).Units };
   end % if ( ( NumCC > 0 ) && FileInfo.HaveUnits )

   FileInfo.FileName = FileList;


      % Allocate the file information arrays.  Reset the total number of lines.

   FileInfo.Time     = zeros( FileInfo.TotLines, NumCols, 'single' );
   FileInfo.TotLines = uint32( 0 );


      % Read all the files.

   for File=1:NumFiles


         % Open a FAST-style data file.

      fid = fopen( FileList{File}, 'rt' );

      if ( fid < 0 )
         beep
         error( '  Could not open "%s" for reading.', FileList{File} );
      end

      fprintf( '  Reading "%s" (%f MB).\n', FileList{File}, FileSize/1024^2 );


         % Get the title line from header.  Store the starting line number for this file.

      HeadLines = textscan( fid, '%s', FirstDataLine-1, 'delimiter', '\n' );

      if ( TitleLine > 0 )
         FileInfo.Title{File} = HeadLines{1}{TitleLine};
      end % if

      FileInfo.StartLine(File) = FileInfo.TotLines + 1;


         % Read the numeric data and store it in the time-series matrix.

      TextData = textscan( fid, '' );

      if ( size( TextData, 2 ) ~= NumIC )
         beep
         if ( File == 1 )
       %     fprintf( '\n  Do you have white space in any of your channel names, because the number\n' );
       %     fprintf( '  of channels expected differs from what is in the first file.\n' );
            error( sprintf( [ '\n  Do you have white space in any of your channel names?  The number\n', ...
                              '  of channels expected differs from what is in the first file.\n' ] ) );
         else
            error( '  All files must have the same number of columns.' );
         end % if
      end % if

      FileInfo.NumLines(File) = size( TextData{1}, 1 );


      if ( FileInfo.HaveNames )
         FileInfo.Time((FileInfo.TotLines+1):(FileInfo.TotLines+FileInfo.NumLines(File)),1:NumIC) = single( [ TextData{:} ] );
      else
         for Col=1:NumIC
            for Row=1:FileInfo.NumLines(File)
               FileInfo.Time((FileInfo.TotLines+Row),Col) = FileInfo.Scales(Col)*single( TextData{Col}(Row) ) + FileInfo.Offsets(Col);
            end % for Row
         end % for Col
      end % if

      FileInfo.TotLines = FileInfo.TotLines + FileInfo.NumLines(File);

      fprintf( '    Rows=%d, Cols=%d\n', FileInfo.NumLines(File), NumCols );


         % Close the data file.

      fclose ( fid );

   end % for File


      % Add the calculated-channel data.

   if ( NumCC > 0 )
      for CC=1:NumCC
         FileInfo.Time(:,NumIC+(CC)) = cell2mat( arrayfun( @(Chan)eval( CalcChan(Chan).Eqn ), CC, 'UniformOutput', false ) );
      end % for CC
   end % if ( NumCC > 0 )


      % A more readable form of the above:

   %for Chan=1:NumCC
   %   FileInfo.Time(:,NumIC+Chan) = eval( CalcChan(Chan).Eqn );
   %end % for


      % Delete the unused rows from the time series.

   FileInfo.Time((FileInfo.TotLines+1):size(FileInfo.Time,1),:) = [];

   fprintf( '  Done\n' );

   return

end % function ReadManyFiles
