function HRootFromLocal = parseSolidWorksTransform(nativeArray)
%PARSESOLIDWORKSTRANSFORM Convert a SolidWorks row-vector transform to MATLAB.

values = double(nativeArray(:));
if numel(values) ~= 16 || any(~isfinite(values))
    error("TrackerModel:MalformedTransform", ...
        "SolidWorks transform must contain 16 finite values.");
end
if abs(values(13) - 1) > 1e-12 || any(abs(values(14:16)) > 1e-12)
    error("TrackerModel:MalformedTransform", ...
        "SolidWorks transform has an invalid homogeneous/scale tail.");
end

Tsw = [values(1:3).', 0; values(4:6).', 0; values(7:9).', 0; ...
    values(10:12).', values(13)];
HRootFromLocal = Tsw.';
HRootFromLocal(4, :) = [0 0 0 1];

R = HRootFromLocal(1:3, 1:3);
if norm(R.' * R - eye(3), "fro") > 1e-9 || abs(det(R) - 1) > 1e-9
    error("TrackerModel:MalformedTransform", ...
        "SolidWorks transform rotation is not a proper orthonormal matrix.");
end
end
