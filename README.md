<p align="center">
<a href="https://dclimate.net/" target="_blank" rel="noopener noreferrer">
<img width="50%" src="https://user-images.githubusercontent.com/41392423/173133333-79ef15d0-6671-4be3-ac97-457344e9e958.svg" alt="dClimate logo">
</a>
</p>

# Introduction
This repo contains a collection of [Jupyter notebooks](https://jupyter.org/) (within the `/notebooks` folder) to easily get started reading and writing GIS Data using IPFS via dClimate's [py-hamt library](https://github.com/dClimate/py-hamt) and [ETL-Scripts](https://github.com/dClimate/etl-scripts) respectively. To learn more, start with `/notebooks/Getting Started.ipynb` 

# Usage
There are a few ways to begin using this repo:

- Running locally:
    - Ensure you first have docker installed. If you do not, head over to https://www.docker.com/ and install docker (it's free!). Ensure the docker daemon is running. Make sure in terminal you are in the root of the directory where you should see a `docker-compose.yml` file if you run `ls`. From the same directory just run `docker compose up` and in your terminal you should see some logs such as IPFS (Kubo) Starting alongside the Jupyter notebook. You should then be able to access the notebook by visiting http://127.0.0.1:8888 in your browser using the key set within the `docker-compose.yml` file. The default is set to `your_secure_token`. Running via Docker ensures you don't have to worry about conda environments, your python version, package managers etc. To simply install another package make sure to use `uv` by using `!uv pip install`.
- Running on [Github Codespaces](https://docs.github.com/en/codespaces/overview): If you found this repo on github you can simply go over to the Github repo over at https://github.com/dClimate/jupyter-notebooks tap `Code` -> `Codespaces` -> `+ (Create Codespace)`. This will bring you to a page which takes up to a minute to load but you can interact with the deployed container either through an in browser editor (where you can run the cells) or [connect your local VSCode](https://docs.github.com/en/codespaces/developing-in-a-codespace/using-github-codespaces-in-visual-studio-code) to the Jupyter notebook running on Github. Note: Github provides a certain amount of free minutes before they begin to charge
- Deploying on Railway. Railway is a PaaS (Platform as a Service) tool similar to heroku which makes launching apps a breeze. As long as you have an account you can deploy applications using templates without any configuration. What's more is that if your costs remain below $5 a month (which the IPFS notebook does) it remains free! You can find the template to deploy [here](https://railway.com/template/oaqTcv?referralCode=1CR-cB). Tap `deploy now` to get started. Once the deployment has finished and you see a green checkmark visit the URL listed under "deployments", it should be a "****.railway.app" url. If you get an error, wait 30 seconds and refresh. Then use the secure token you set when you deployed the template to login. 

# Development Guide
## Setting Up
This repo uses [uv](https://docs.astral.sh/uv/) for dependency management, Docker for isolating environments (so that nothing is exposed to the machine running the code aside from ports), IPFS within docker for accessing the wider IPFS network, and Jupyter for running python notebooks.

There is a `requirements.txt` file which has base requirements which will exist for all deployments however it currently only has jupyter related requirements.To test any changes simply run `docker compose up` ensuring to clear out any images or volumes during development which can be left hanging.

The `scripts/start.sh` file ensures all necessary IPFS commands are run. This file can be used for other tooling if needed.