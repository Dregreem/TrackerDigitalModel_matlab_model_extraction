function [H_ground_from_F0, info] = trackerDisplayTransform(model)
%TRACKERDISPLAYTRANSFORM Ground-align F0 for MATLAB visualization only.
% The engineering model remains in F0. Display +Z is physical F0 +Y.

settings = trackerModelSettings();
R = settings.display.R_ground_from_F0;
b0Indices = model.groups.B0.componentIndices;
minimumB0HeightF0 = inf;
for componentIndex = b0Indices(:).'
    geometryIndex = find([model.geometry.components.componentIndex] == componentIndex, 1);
    minimumB0HeightF0 = min(minimumB0HeightF0, ...
        min(model.geometry.components(geometryIndex).vertices_F0(:,2)));
end
translation = [0; 0; -minimumB0HeightF0];
H_ground_from_F0 = [R, translation; 0 0 0 1];

info.upAxisF0 = [0;1;0];
info.upAxisDisplay = R * info.upAxisF0;
info.minimumB0HeightF0 = minimumB0HeightF0;
info.groundLevelDisplay = 0;
info.isDisplayOnly = true;
end
