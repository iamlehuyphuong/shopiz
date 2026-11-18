# Contributing to Shopiz

Thanks for taking the time to contribute! Bug reports, feature ideas, translations and pull requests are all welcome.

Bạn có thể viết issue và pull request bằng tiếng Việt hoặc tiếng Anh.

## Reporting bugs and requesting features

- Search [existing issues](https://github.com/iamlehuyphuong/shopiz/issues) first.
- Use the issue templates. Include steps to reproduce, what you expected, and your setup (self-hosted with Docker, Linux VM, etc.).
- Report security vulnerabilities privately. See [SECURITY.md](./SECURITY.md).
- If a bug also exists in upstream Chatwoot and is not related to Shopiz changes, consider reporting it to [Chatwoot](https://github.com/chatwoot/chatwoot/issues) as well.

## Development setup

See [Getting started](./README.md#getting-started) in the README. In short:

```bash
bundle install && pnpm install
bundle exec rails db:chatwoot_prepare
pnpm dev
```

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Keep each PR focused on one change. Small PRs get reviewed faster.
3. Run the linters and the relevant tests:
   ```bash
   pnpm eslint
   bundle exec rubocop -a
   pnpm test
   bundle exec rspec spec/path/to/file_spec.rb
   ```
4. Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages and PR titles, for example `feat(zalo): sync group members`.
5. In the PR description, explain the user-facing change, link related issues, and add steps to test it.

## Code guidelines

- Ruby: follow RuboCop rules (150 character line limit).
- Vue: Composition API with `<script setup>`, PascalCase component names, Tailwind utility classes only (no custom or scoped CSS).
- No hardcoded strings in the UI. Add frontend strings to `en.json` and backend strings to `en.yml`. Vietnamese translations are welcome in the `vi` files.
- Prefer small, readable changes over new abstractions.

[AGENTS.md](./AGENTS.md) has the full set of conventions.

## Upstream code

Shopiz is a fork of [Chatwoot](https://github.com/chatwoot/chatwoot) and regularly merges upstream releases. When you change Chatwoot code, keep the change as small as possible so future merges stay easy.

## License

By contributing, you agree that your contributions are licensed under the same terms as the files you change. See [LICENSE](./LICENSE).
