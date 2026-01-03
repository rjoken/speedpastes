# speedpastes

Speedpastes.org is an open source, invite-only, social note-taking platform which serves as an alternative to the malware-ridden `pastebin`.

## Getting Started

Get [nix](https://install.determinate.systems/#products) and [direnv](https://direnv.net/#getting-started).

Remember to configure your shell to use direnv! Add the following lines at the end of your ~/.bashrc:

`eval "$(direnv hook bash)"`

Then open your terminal and do

```shell
git clone git@github.com:rjoken/speedpastes.git
cd speedpastes
```

If you have everything set up correctly, direnv should complain:

```shell
direnv: error /home/username/speedpastes/.envrc is blocked. Run `direnv allow` to approve its content
```

If it doesn't, please check [it is hooked correctly into your SHELL](https://direnv.net/docs/hook.html).

Once you see the error message, simply run:

```shell
direnv allow
```

Follow the prompts, and allow it to download the packages it needs. Once done, run:

```shell
bundle install
```

Once dependencies are installed, simply run:

```shell
dev
```

to start all services locally.

## Databases

speedpastes will start a postgresql instance on port 6666.
You may modify the DEV_DATABASE_URL if you want to point speedpastes do a different database.

## Authentication

TODO

## Testing

TODO

## Deployment Instructions

TODO
