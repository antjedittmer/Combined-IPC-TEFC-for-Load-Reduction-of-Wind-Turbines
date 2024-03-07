function MCrunch ( SettingsFile )
% Analyze time-series data in many different ways.
%
% Syntax is:  MCrunch( SettingsFile );
%
% Example:
%     MCrunch( 'MySettings.mcru' );
%
% See also CompFatigue, GenBins, GenExtEvts, GenPDFs, GenPSDs, GenRFPlots,
%          GenStats, GenTimePlots, ReadManyFiles, ReadSettings

   %SettingsFile = 'Test_02.mcru';

   global AggRoot Binning ChartPosition EchoInp Fatigue FigTitles FileInfo LineWidth OutData PDF ProgName PSD RealFmt SaveFigs StrFmt StrFmtL UnEc

   ProgName = 'MCrunch (v1.00.00y-mlb, 04-May-2009)';

   fprintf( '\n  Running %s\n\n', ProgName );

   ReadSettings;

   ReadManyFiles( FileList, TitleLine, NamesLine, UnitsLine, FirstDataLine, CalcChan );


      % Time Series.

   if ( ~isempty( TimePlots ) )
      GenTimePlots( TimePlots )
   end % if


      % Statistics and (possibly) extreme events.

   if ( DoStats )

      GenStats( SumStatChans, WrStatsTxt, WrStatsXLS, SettingsFile );

      if ( ~isempty( EEvTable ) )
         GenExtEvts( EEvTable );
      end % if

   end % if


      % Binning.

   if ( DoBins )
      GenBins( UseBinAv, PltBins, PltRawData, WrBinsTxt, WrBinsXLS, SettingsFile );
   end % if


      % Probability Denisty Functions.

   if ( DoPDFs )
      GenPDFs( SettingsFile );
   end % if


      % Power Spectral Denisty.

   if ( DoPSDs )
      GenPSDs( SettingsFile );
   end % if


      % Fatigue Analysis.

   if ( DoFatigue )


         % For now, let's just do one or the other.

      if ( Fatigue.DoLife )

         CompLife( SettingsFile );

      else

         CompFatigue( SettingsFile );

         if ( Fatigue.DoFatPlots )
            GenRFPlots( SettingsFile );
         end % if

      end % if

   end % if

   fprintf( '\n  MCrunch Processing complete.\n\n' );

end % function MCrunch ( SettingsFile )
