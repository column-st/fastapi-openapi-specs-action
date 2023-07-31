# FastAPI OpenAPI Specs Action

This is a simple GitHub action intended on automatically generating the `openapi.yaml` (or `openapi.json`) file for FastAPI projects. Intended on being used in conjunction with other actions to create complete workflows.

# Inputs

| Label | Icon |
|-|-|
| 🟢 | Required |
| 🟡 | Required but defaults |
| 🔴 | Not required |

| Name | Description | Required | Default |
|-|-|-|-|
| `installDependencies` | Command used to install dependencies before running FastAPI application. This command runs as a standard shell command. | 🟡 | `pip install -r requirements.txt` |
| `moduleDir` | The directory in which the FastAPI Python app lives. This should be the first folder in your project with a `__init__.py` file. | 🟢 |  |
| `fileName` | The file from which your FastAPI application gets initialized. | 🟡 | `main.py` |
| `appName` | The name of the FastAPI object inside your `{moduleDir}/{fileName}.py`. This is used to do `from {moduleDir}.{fileName} import {appName}`. | 🟡 | `app` |
| `fastapiVersioning` | Only use this if your application uses the `fastapi-versioning` package.  If the `fastapi-versioning` is being used each version of your application has its own individual FastAPI app that is ran in conjunction. This variable defines which FastAPI API to use to generate the client. Use the package's `VersionedFastAPI.prefix_format` string,  something like `v{number}` typically (e.g. `v1`). | 🔴 | `None` |
| `outputName` | The name of the output file without the extension. | 🟡 | `openapi` |
| `outputExtension` | Output extension. May be either `yaml` or `json`. | 🟡 | `yaml` |

# Output

A new file called `{outputName}.{outputExtension}` is created in the current directory. 

## Example Usage

The example below is a complete example that utilizes the `fastapi-openapi-specs-action` with the [`openapitools-generator-action`](https://github.com/triaxtec/openapitools-generator-action) to automatically generate the FastAPI client code and publish it to the repository under the branch `client`.

```yaml
name: Generate Client

# Runs this action whenever there are any changes to the master branch.
on:
  push:
    branches:
      - master

jobs:
  client:
    runs-on: ubuntu-latest

    # Checks out the entire repo.
    steps:
    - name: Checks out repo
      uses: actions/checkout@v1

    # Generates a openapi.yaml file based on the FastAPI project.
    - name: Generate OpenAPI file
      uses: column-street/fastapi-openapi-specs-action@v1.0.0
      with:
        moduleDir: collector
        fileName: main.py
        appName: app
        fastapiVersioning: v1

    # Uses an external tool, openapitools-generator-action, to generate the client code.
    # The 'openapirc.json' file is the following: { "packageName": "collector", "projectName": "collector" }
    # and it lives inside the master branch of the repository. Command outputs a new folder called 
    # 'python-client' with the relevant client code.
    - name: Generate Python Client
      uses: triaxtec/openapitools-generator-action@v1.0.0
      with:
        generator: python
        openapi-file: openapi.yaml
        config-file: openapirc.json

    # Deletes every file in the folder, except '.git' and the new generated 'python-client' folder.
    # Moves all content of the 'python-client' folder to the root directory.
    - name: Cleans the branch up.
      run: |
        # Removes all files except the .git and python-client folder.
        shopt -s extglob
        sudo rm -rf !(.|..|.git|python-client)
        # Moves all of the content of the python-client folder out, 
        # and deletes the folder.
        mv python-client/* .
        rm -rf python-client

    # Commits the new changes into a new branch called 'client'.
    - name: Commit changes.
      run: |
        git checkout -b client
        git config --local user.email "action@github.com"
        git config --local user.name "GitHub Action"
        git add .
        git commit -m "Generated client." -a || true 

    # Pushes all of these changes into the GitHub repository.
    - name: Push changes to client branch
      uses: ad-m/github-push-action@master
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        branch: client
        force: True
```
