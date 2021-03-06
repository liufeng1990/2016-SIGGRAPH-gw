%% Load mesh, put into convenient data structure

[X,T] = readOff('../data/meshes/octopus1.off');
n0 = size(X,1);
M0 = getMeshData(X,T);

[X,T] = readOff('../data/meshes/octopus2.off');
n = size(X,1);
M = getMeshData(X,T);

%% Compute full distance matrix

fprintf('Computing pairwise geodesic distance...\n');

D0 = zeros(n0,n0);
for i=1:n0
    D0(:,i) = perform_fast_marching_mesh(M0.vertices,double(M0.triangles),i);
end
D0 = D0 + D0'; % Symmetrize -- fast marching may not be symmetric (I think)

D = zeros(n,n);
for i=1:n
    D(:,i) = perform_fast_marching_mesh(M.vertices,double(M.triangles),i);
end
D = D + D';

%% Compute Gromov-Wasserstein

fprintf('Optimizing regularized Gromov-Wasserstein...\n');

options = [];

options.mu0 = M0.areaWeights;
options.mu = M.areaWeights;
options.display = 1;
options.regularizer = .0007;
options.plotObjective = 1;
options.maxIter = 50;
options.GWTol = 0; % run all 50 iterations

etas = {1/2^4,1/2^3,1/2^2,1/2,1,2};
gammas = [];
objectives = [];
for i=1:length(etas)
    options.eta = etas{i};
    [gammas{i},objectives{i}] = gromovWassersteinDistance(D0,D,options);
end

%% Plot convergence with different etas

figure;
legends = [];
for i=1:length(objectives)
    plot(objectives{i}(1:50));
    legends{i} = sprintf('eta=%g',etas{i});
    hold on;
end
legend(legends);
xlabel('Iteration');
ylabel('Objective value');
title('Effect of eta on convergence');

%% Write out in a TikZ-friendly way

fid = fopen(sprintf('data_%g.txt',options.regularizer),'w');
for i=1:length(objectives{1})
    fprintf(fid,'%d,',i);
    for j=1:length(objectives)
        fprintf(fid,'%g',objectives{j}(i));
        if j~=length(objectives)
            fprintf(fid,',');
        else
            fprintf(fid,'\n');
        end
    end
end
fclose(fid);

%% Illustrate map in a corny way -- just select out some points randomly

% nPoints = 2;
% points = [277 97];
% 
% for i=1:nPoints
%     p = points(i);
%     figure;
%     
%     fig = subplot(1,2,1);
%     f = zeros(n0,1); f(p) = 1;
%     showDescriptor(M0,f,[],[],[],fig); colorbar off; hold on;
%     plot3(M0.vertices(p,1),M0.vertices(p,2),M0.vertices(p,3),'.','markersize',50,'markeredgecolor',[1 0 0]);
%     title('Source');
%     
%     fig = subplot(1,2,2);
%     showDescriptor(M,gamma(p,:)',[],[],[],fig); colorbar off;
%     title('Target');
% end
% 
% %% Write meshes
% 
% gg = gamma(points,:);
% gg(1,:) = 0;
% generateSoftMapMeshes(M0,M,'source_octopus.obj',sprintf('target_octopus1_%g.obj',options.regularizer),...
%     [],[],points,gg',.1);
% 
% gg = gamma(points,:);
% gg(2,:) = 0;
% generateSoftMapMeshes(M0,M,'source_octopus.obj',sprintf('target_octopus2_%g.obj',options.regularizer),...
%     [],[],points,gg',.1);
% 
% close all