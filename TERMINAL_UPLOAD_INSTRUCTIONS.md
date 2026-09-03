# TERMINAL_UPLOAD_INSTRUCTIONS.md

## 1. Create an empty GitHub repository

Create a new **private** repository, recommended name:

```text
TrackerDigitalModel
```

For the cleanest first push, do **not** initialize it with a README, `.gitignore`, or license.

Copy its HTTPS URL, for example:

```text
https://github.com/Dregreem/TrackerDigitalModel.git
```

## 2. Put these handoff files in the local MATLAB project root

Your current project root is expected to be:

```text
C:\Users\Kerem Bayer\Desktop\KBStracker\Kerem_astro\Matlab_model_extraction
```

Place/merge:

```text
AGENTS.md
PROJECT_STATE.md
README.md
.gitignore
bootstrap_github_repo.ps1
```

Also keep your existing project files:

```text
TrackerDigitalModel.prj
matlab/
tests/
config/
reports/
CONTRACT/
```

Move/copy the accepted CAD Bridge V2 export into:

```text
cad\baseline\S0_ZERO\
```

The baseline folder should contain:

```text
manifest.json
components.json
mates.json
geometry_root_triangles.csv
component_tree.txt
export_log.txt
```

Do not commit raw `.SLDASM/.SLDPRT` files unless you intentionally decide to use Git LFS.

## 3. Run from PowerShell

```powershell
cd "C:\Users\Kerem Bayer\Desktop\KBStracker\Kerem_astro\Matlab_model_extraction"

Set-ExecutionPolicy -Scope Process Bypass

.\bootstrap_github_repo.ps1 `
  -RepoUrl "https://github.com/Dregreem/TrackerDigitalModel.git"
```

The script:

- initializes Git if needed,
- sets/updates `origin`,
- uses `main`,
- checks for files >=100 MB,
- stages the full project,
- creates the checkpoint commit if needed,
- pushes to GitHub.

## 4. After the initial checkpoint

Create a local development branch:

```powershell
git checkout -b dev/phase2a
git push -u origin dev/phase2a
```

Keep `main` as the accepted checkpoint.

## 5. Verify

```powershell
git status
git remote -v
git log --oneline --decorate -5
```

Then open the GitHub repository in the browser and confirm the following are present:

```text
AGENTS.md
PROJECT_STATE.md
CONTRACT/
cad/baseline/S0_ZERO/
config/
matlab/
tests/
reports/
TrackerDigitalModel.prj
```

## 6. Shared-development continuity

Once the repository is pushed, give ChatGPT GitHub access to that repository when convenient.
Local work does not depend on that connection; it is only needed for ChatGPT to directly read/write branches and PRs.

Every accepted checkpoint should update:

```text
PROJECT_STATE.md
```
