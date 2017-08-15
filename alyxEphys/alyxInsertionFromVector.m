
function [entryRL, entryAP, vertAngle, horizAngle] = alyxInsertionFromVector(m, p, av, st)
% function [entryRL, entryAP, vertAngle, horizAngle] = alyxInsertionFromVector(m, p)
%
% From a vector and point on the vector, determine the entry point and
% angles as specified in alyx (stereotax)
%
% m - 3x1 point in allen CCF coordinates (units µm)
% p - 3x1 vector in allen CCF coordinates [ap; dv; lr]

voxelSize = 10; % µm

p = p(:)./norm(p);
m = m(:);

% ensure proper orientation: want 0 at the top of the brain and positive
% distance goes down into the brain (opposite of the probe, but works with
% scaling better)
if p(2)<0
    p = -p;
end

% move down into the brain just a bit, in case we're starting at the
% surface
m = m+p*voxelSize*10;

% Work out the point of intersection with the brain
ann = 10;
gotToCtx = false;
isoCtxId = num2str(st.id(strcmp(st.acronym, 'Isocortex')));
while ~(ann==1 && gotToCtx) %ann==1 is "root" i.e. outside brain
    m = m-p*voxelSize; % step 10um, backwards up the track
    inds = round(m./voxelSize);
    ann = av(inds(1),inds(2),inds(3));
%     fprintf(1, '%s\n', st.acronym{ann});
    if ~isempty(strfind(st.structure_id_path{ann}, isoCtxId))
        % if the track didn't get to cortex yet, keep looking, might be in
        % a gap between midbrain/thal/etc and cortex. Once you got to
        % isocortex once, you're good. 
        gotToCtx = true;
    end    
    
end

ccfBregma = allenCCFbregma*voxelSize;
entryRL = m(3)-ccfBregma(3); 
entryAP = -(m(1)-ccfBregma(1));
% dv position is the intersection with the brain at this AP/RL coord

% compute the two angles

% docstring:
% - horizontal angle of probe (degrees), after vertical rotation. 
% Zero means anterior. Positive means counterclockwise (i.e. left).
%
% So this is solely determined by the AP and RL parts of the vector
% apV = p(1); 
% rlV = -p(3);
% horizAngle = 180-atand(rlV/apV);
horizVec = [p(1) p(3)]; horizVec = horizVec./norm(horizVec);
horizAngle = acosd(-horizVec(1)); % angle between [-1 0] and horizVec (both are length=1) 
if p(3)>0
    horizAngle = 360-horizAngle;
end

% docstring:
% - vertical angle of probe (degrees). Zero means horizontal. Positive means pointing down.
dvV = p(2);
lateralV = sqrt(p(1).^2+p(3).^2);
vertAngle = atand(dvV/lateralV);



