
function [ccfCoords, ccfOntology] = alyxLocationFromInsertion(entryRL, entryAP, vertAngle, horizAngle, axialAngle, distAdvanced, siteCoords, av, st)
% function [ccfCoords, ccfOntology] = alyxLocationFromInsertion(entryRL, entryAP, vertAngle, horizAngle, axialAngle, distAdvanced, siteCoords, av, st)
%
% Returns the CCF ap/dv/lr coords and acronyms given the numbers that
% define the insertion (position and angle) as well as the site positions
% in probe coordinates.
%
% Inputs:
% - entryRL, entryAP, vertAngle, horizAngle, axialAngle, distAdvanced - each a single
% number, defined according to the alyx documentation (relevant section
% copied at the bottom of this function). All units degrees and microns.
% - siteCoords is nSites x 2, microns, site positions relative to tip
% - av, st are allenCCF data - annotation_volume_by_index and
% structure_tree
%
% Outputs:
% - ccfCoords - nSites x 3, microns, the 3d coordinates of every site
% - ccfOntology - cell array of size nSites x 1, contains the acronym of
% the structure at each site.


voxelSize = 10; %µm

% work out the 3D position of the insertion point - where you hit brain
% first coming down from the stereotax position
ccfBregma = allenCCFbregma;
ccfAP = -entryAP/voxelSize+ccfBregma(1);
ccfRL = entryRL/voxelSize+ccfBregma(3);
ccfDV = find(squeeze(av(round(ccfAP),:,round(ccfRL)))~=1, 1);
ccfEntry = [ccfAP ccfDV ccfRL]*voxelSize;

% do our probe rotations in stereotax, where: 
% +X is right
% +Y is anterior
% +Z is dorsal
p = [0 1 0]'; % unrotated probe - vector pointing to the tip
probeX = [-1 0 0]'; % looking at the face of the probe, the +x direction is to the right
 % but we are looking at it from above so this axis is left. 
 
Rx = @(t)[1 0 0; 0 cosd(t) -sind(t); 0 sind(t) cosd(t)];  
Ry = @(t)[cosd(t) 0 sind(t); 0 1 0; -sind(t) 0 cosd(t)]; 
Rz = @(t)[cosd(t) -sind(t) 0; sind(t) cosd(t) 0; 0 0 1];

% first axial rotation of our X dimension
probeXRot = Ry(-axialAngle)*probeX; % use -axial because we're going from left -> ventral, i.e. -x to -z

pRot = Rz(horizAngle)*Rx(-vertAngle)*p; % use -vert because we want to go from +Y towards -Z
probeXRot2 = Rz(horizAngle)*Rx(-vertAngle)*probeXRot;

% now switch to CCF directions, where:
% +X is posterior
% +Y is ventral
% +Z is right
pCCF = [-pRot(2) -pRot(3) pRot(1)];
probeXCCF = [-probeXRot2(2) -probeXRot2(3) probeXRot2(1)];

% "advance the tip" 
tip = ccfEntry+pCCF.*distAdvanced;

% now define the axes of the probe
probeYCCF = -pCCF; % p was going down towards the tip, probeY comes back up

% site coords in 3D, then
ccfCoords = tip+siteCoords*[probeXCCF; probeYCCF];

% labels for all these sites
vx = round(ccfCoords/voxelSize);
avInds = arrayfun(@(x)av(vx(x,1), vx(x,2), vx(x,3)),1:size(ccfCoords,1));
ccfOntology = st.acronym(avInds);



% doc from alyx: 
%     entry_point_rl = models.FloatField(null=True, blank=True,
%                                        help_text="mediolateral position of probe entry point "
%                                        "relative to midline (microns). Positive means right")
% 
%     entry_point_ap = models.FloatField(null=True, blank=True,
%                                        help_text="anteroposterior position of probe entry point "
%                                        "relative to bregma (microns). Positive means anterior")
% 
%     vertical_angle = models.FloatField(null=True, blank=True,
%                                        help_text="vertical angle of probe (degrees). Zero means "
%                                        "horizontal. Positive means pointing down.")
% 
%     horizontal_angle = models.FloatField(null=True, blank=True,
%                                          help_text="horizontal angle of probe (degrees), "
%                                          "after vertical rotation. Zero means anterior. "
%                                          "Positive means counterclockwise (i.e. left).")
% 
%     axial_angle = models.FloatField(null=True, blank=True,
%                                     help_text="axial angle of probe (degrees). Zero means that "
%                                     "without vertical and horizontal rotations, the probe "
%                                     "contacts would be pointint up. Positive means "
%                                     "counterclockwise.")
% 
%     distance_advanced = models.FloatField(null=True, blank=True,
%                                           help_text="How far the probe was moved forward from "
%                                           "its entry point. (microns).")
% 
