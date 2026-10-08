% Run examples/capsule-stl.rkt first, then run this file from the directory
% containing capsule-mm.stl. This example keeps OpenEMS policy downstream of
% the general-purpose manifold package.
pkg load openems;
pkg load csxcad;

CSX = InitCSX();
CSX = AddMetal(CSX, 'capsule');
CSX = ImportSTL(CSX, 'capsule', 10, 'capsule-mm.stl');

mesh.x = -3:1:3;
mesh.y = -3:1:3;
mesh.z = -3:1:13;
CSX = DefineRectGrid(CSX, 1e-3, mesh); % STL coordinates are millimetres.

FDTD = InitFDTD('NrTS', 1);
FDTD = SetGaussExcite(FDTD, 1e9, 5e8);
FDTD = SetBoundaryCond(FDTD, {'MUR' 'MUR' 'MUR' 'MUR' 'MUR' 'MUR'});
WriteOpenEMS('capsule-smoke.xml', FDTD, CSX);

% Validate geometry import without running the simulation:
%   openEMS capsule-smoke.xml --no-simulation --debug-CSX

