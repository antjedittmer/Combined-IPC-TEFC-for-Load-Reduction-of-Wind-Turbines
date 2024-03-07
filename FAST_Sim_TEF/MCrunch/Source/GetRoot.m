function RootName = GetRoot( GivenFile )
% Get the root part of a file name stored in a string array.
%
% If the string contains a period, everything up to, but not including,
% the last period will be returned as RootName.  If GivenFile contains
% no period, RootName will be set to GivenFile.
%
% Syntax is:  GetRoot( GivenFile )
%
% Example:
%
%     GetRoot( 'Myfile.txt' )
%
% See also CompFatigue, GenBins, GenExtEvts, GenPDFs, GenPSDs, GenRFPlots,
%          GenStats, MCrunch, ReadSettings


   % Deal with a couple of special cases.

if ( strcmp( GivenFile, '.' ) || strcmp( GivenFile, '..' ) )
   RootName = GivenFile;
   return
end


   % More-normal cases.

for Char = size( GivenFile, 2 ):-1:1

   if ( strcmp( GivenFile(Char), '.' ) )


         % Check for something such as "..\Myfile" if the period is not at the end of the file name.

      if ( Char < size( GivenFile, 2 ) )

         if ( isempty( findstr( filesep, GivenFile(Char+1) ) ) )
            RootName = GivenFile(1:Char-1);                       % The period is a normal extension separator.
         else
            RootName = GivenFile;                                 % The period was part of a path and not an extension separator.
         end
      else
         RootName = GivenFile(1:Char-1);                          % The period was at the end of the name (no extension).
      end

      return

   end

end

RootName =  GivenFile;                                            % There were no periods in the file name (no extension).

return
