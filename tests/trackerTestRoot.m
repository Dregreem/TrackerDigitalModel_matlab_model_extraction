function root = trackerTestRoot()
%TRACKERTESTROOT Return the repository root for tests.
root = fileparts(fileparts(mfilename("fullpath")));
end
