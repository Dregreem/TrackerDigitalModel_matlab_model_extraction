function trianglesF0 = convertGeometryRootToF0(trianglesRoot, H_F0_from_root)
%CONVERTGEOMETRYROOTTOF0 Convert N-by-9 triangle coordinates into F0.

arguments
    trianglesRoot (:,9) double
    H_F0_from_root (4,4) double
end

pointsRoot = reshape(trianglesRoot.', 3, []);
pointsF0Homogeneous = H_F0_from_root * [pointsRoot; ones(1, size(pointsRoot, 2))];
trianglesF0 = reshape(pointsF0Homogeneous(1:3, :), 9, []).';
end
