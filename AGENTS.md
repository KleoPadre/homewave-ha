# HomeWave Development Rules

## Language

- Write commit messages, source code, configuration, CI definitions, comments, and primary documentation in English.
- Keep Russian text only in intentionally localized artifacts, including `README.ru.md` and `translations/ru.yaml`.

## Branches and Git

- `main` is the release branch. It must contain only files required to build, test, document, and distribute the HomeWave add-on.
- Do not commit implementation plans, agent instructions, agent workspace files, prompts, transcripts, or other AI working material to `main`.
- Keep planning and agent-only files on `dev` or on feature branches.
- Use concise English Conventional Commit messages, for example `feat: add PulseAudio output`.
- Push every completed commit to its corresponding remote branch.
- Before pushing to `main`, verify its file list with `git ls-tree -r --name-only main` and its commit subjects with `git log main --format='%s'`.

## Release Quality

- Do not claim stable audio playback until the automated checks and the real-device acceptance checklist both pass.
- Do not publish secrets, `/data/options.json`, or real local network addresses in commits, documentation, or logs.
