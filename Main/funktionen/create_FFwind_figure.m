function create_FFwind_figure(BTSfilePath,WindPlotsFolderPath)
%% function that plots wind speeds from a TurbSim .bts file

    [velocity, twrVelocity, y, z, zTwr, nz, ny, dz, dy, dt, zHub, z1,mffws] = readfile_BTS(BTSfilePath);
   
    nt = size(velocity,1);
    t = (0:(nt-1))*dt;
    
   % xSlice = [t(1) t(end)]
    
    xSlice = [linspace(t(1),t(end),7)]
    ySlice = [y(1) ];
    zSlice = [z(1) ];

    V = sqrt(squeeze(velocity(:,1,:,:)).^2 + squeeze(velocity(:,2,:,:)).^2 + squeeze(velocity(:,3,:,:)).^2);
    WindPlot = figure;
    %h=slice(y,t,z, V, ySlice, xSlice, zSlice );
    h=slice(y,t,z, V, [], xSlice, []);
    set(h,'FaceAlpha',0.999,'EdgeColor',"black")
    %alpha('color');
    colormap(jet);
    daspect([1,1,1])
    view(50,30)
    xlabel('y (m)')
    ylabel('time (s)')
    zlabel('z (m)')
    title('Betrag der Windgeschwindigkeit (m/s)')
    colorbar
    
    hold on 
    h=slice(y,t,z, V, ySlice, [], zSlice);
    set(h,'FaceAlpha',0.999,'EdgeColor',"none")
    
    hold off
    
    
    % Speichern der Figure
    [~,BTSFileName,~] = fileparts(BTSfilePath);
    saveas(WindPlot,fullfile(WindPlotsFolderPath,strcat(BTSFileName,'_Wind_Plot.fig')));
    
end
