function DelSheet1( WorkBook )
% Delete the empty "Sheet1" from an Excel Workbook.
% Sheet1 is created by xlswrite() and is left blank.
%
% There is no error checking in this function.  It assumes that you will call it
% immediately after using xlswrite().
%
% Syntax is DelSheet1( WorkBook )
%
% Example:
%
%     DelSheet1( 'MyWorkBook.xls' )
%
% See also actxserver, DelFile, GenBins, GenPDFs, GenPSDs, GenStats, xlswrite.


   ExcelObj      = actxserver( 'Excel.Application' );
   ExcelWorkbook = ExcelObj.workbooks.Open( [ cd, filesep, WorkBook ] );
   ExcelObj.sheets.Item(1).Delete;
   ExcelWorkbook.Save;
   ExcelWorkbook.Close( false );
   ExcelObj.Quit;
   delete( ExcelObj );

end % function DelSheet1( WorkBook )
