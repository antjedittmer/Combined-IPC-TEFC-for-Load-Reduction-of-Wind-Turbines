function varargout = ReadVal( fid, Type, NumVals, VarName, VarDescr )
% Reading a line from a file or processing a string, look for one or more values
% of a given type to return in the cell array, varargout.
%
% Syntax is:  varargout = ReadVal( fid, Type, NumVals, VarName, VarDescr )
%
%     where:
%        fid:       A file handle or a string.
%        Type:      The type of variable or array to scan for.  Options are:
%                       'float'
%                       'integer'
%                       'logical'
%                       'string'
%        NumVals:   The number of values to parse.
%        VarName:   A string that should be set to the variable/array name for
%                   outputting to the echo file.
%        VarDescr:  A string that should be set to the description of the
%                   variable/array name for outputting to the echo file.
%
% Examples:
%   ---------------------------------------------------------------------------------------------
%   TitleLine = cell2mat( ReadVal( '5  TitleLine  The row with the file title on it.', ...
%                         'integer', 1, 'TitleLine', 'The row with the file title on it.' ) );
%   ---------------------------------------------------------------------------------------------
%   LineWidth = cell2mat( ReadVal( '1.5  LineWidth  The width of curves on the plots.', ...
%                         'float', 1, 'LineWidth', 'The width of curves on the plots.' ) );
%   ---------------------------------------------------------------------------------------------
%   TabDelim  = cell2mat( ReadVal( 'true  TabDelim  Generate output in tab-delimited form?', ...
%                         'logical', 1, 'TabDelim', 'Generate output in tab-delimited form?' ) );
%   ---------------------------------------------------------------------------------------------
%   RealFmt   = cell2mat( ReadVal( '"%11.3e"  RealFmt  Format for floating-point values.', ...
%                         'string', 1, 'RealFmt' , 'Format for floating-point values.' ) );
%   ---------------------------------------------------------------------------------------------
%   temp = ReadVal( '80 23 24 26 27 29 30  PSDChans  List of PSD channels.', ...
%          'integer', NumPSDChans, 'PSDChans', 'List of PSD channels.' );
%   for Ch=1:NumPDFChans
%      PSD.Chans(Ch) = temp{Ch};
%   end % for Ch
%   ---------------------------------------------------------------------------------------------
%
% See also MCrunch, ReadSettings

   global EchoInp UnEc

   switch lower( Type )
   case 'float'

      temp = ReadFloat( fid, NumVals );

   case 'integer'

      temp = ReadInt( fid, NumVals );

   case 'logical'

      temp = ReadLogical( fid, NumVals );

   case 'string'

      temp = ReadString( fid, NumVals );

      for IVal=1:NumVals
         varargout{1}{IVal} = cell2mat( temp(IVal) );
      end % for IVal

      return

   end

   if ( NumVals == 1 )
      varargout{1} = temp;
   else
      for IVal=1:NumVals
         varargout{1}{IVal} = temp{1}(IVal);
      end % for IVal
   end % if

   return

%===============================================================================
   function varargout = ReadFloat( fid, NumVals )

      if ( ishandle( fid ) )
         temp = textscan( fgetl( fid ), '%f', NumVals );
      else
         temp = textscan( fid, '%f', NumVals );
      end % if

      if ( EchoInp )
         fprintf( UnEc, '%-20g  %-15s  %s\n', temp{1}, VarName, VarDescr );
      end % if

      for IVal=1:size( temp, 1 )
         varargout{IVal} = temp(IVal);
      end

      return

   end
%===============================================================================
   function varargout = ReadInt( fid, NumVals )

      if ( ishandle( fid ) )
         temp = textscan( fgetl( fid ), '%d', NumVals );
      else
         temp = textscan( fid, '%d', NumVals );
      end % if

      if ( EchoInp )
         if ( size( temp{1}, 1 ) == 1 )
            fprintf( UnEc, '%-20d  %-15s  %s\n', temp{1}, VarName, VarDescr );
         else
            for IStr=1:size( temp, 1 )
               fprintf( UnEc, '%d ', temp{IStr} );
            end % for IStr
            fprintf( UnEc, '    %-15s  %s\n', VarName, VarDescr );
         end % if
      end % if

      for IVal=1:size( temp, 1 )
         varargout{IVal} = temp(IVal);
      end

      return

   end
%===============================================================================
   function varargout = ReadLogical( fid, NumVals )

      if ( ishandle( fid ) )
         temp = textscan( fgetl( fid ), '%s', NumVals );
      else
         temp = textscan( fid, '%s', NumVals );
      end % if

      if ( EchoInp )
         fprintf( UnEc, '%-20s  %-15s  %s\n', temp{1}{1}, VarName, VarDescr );
      end % if

      for IVal=1:size( temp{1}, 1 )

         switch lower( temp{1}{IVal} )
         case 'true'
            varargout{1}{IVal} = true;
         case 'false'
            varargout{1}{IVal} = false;
         otherwise
            beep
            error( sprintf( '  The logical variable must be "true" or "false".  Instead, it was "%s".', temp ) );
         end

      end % for IVal

      return

   end
%===============================================================================
   function varargout = ReadString( fid, NumVals )

      if ( ishandle( fid ) )
         temp = textscan( fgetl( fid ), '%q', NumVals );
      else
         temp = textscan( fid, '%q', NumVals );
      end % if

      if ( EchoInp )
         if ( size( temp{1}, 1 ) == 1 )
            fprintf( UnEc, '"%s"%s%-15s  %s\n', temp{1}{1}, repmat( ' ', 1, 20-size( temp{1}{1}, 2 ) ),VarName, VarDescr );
         else
            for IStr=1:size( temp{1}, 1 )
               fprintf( UnEc, '"%s" ', temp{1}{IStr} );
            end % for IStr
            fprintf( UnEc, '\n' );
         end % if
      end % if

      for IVal=1:size( temp{1}, 1 )
         varargout{1}{IVal} = temp{1}{IVal};
      end

      return

   end
%===============================================================================

end
