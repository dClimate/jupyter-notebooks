<p align="center">
<a href="https://dclimate.net/" target="_blank" rel="noopener noreferrer">
<img width="50%" src="https://user-images.githubusercontent.com/41392423/173133333-79ef15d0-6671-4be3-ac97-457344e9e958.svg" alt="dClimate logo">
</a>
</p>

# Introduction
This repo contains a collection of [Jupyter notebooks](https://jupyter.org/) (within the `/notebooks` folder) to easily get started reading and writing GIS Data using IPFS via dClimate's [py-hamt library](https://github.com/dClimate/py-hamt) and [ETL-Scripts](https://github.com/dClimate/etl-scripts) respectively. To learn more, start with [/notebooks/Getting Started.ipynb](/notebooks/Getting%20Started.ipynb).

# Usage
There are a few ways to begin using this repo:

- Running locally:
    - First pull down this repo to your machine by tapping the green `Code` button and clone using your preferred method of choice, whether HTTPS, SSH, or downloading a zip. If you download a zip make sure you unzip the file into a folder you can navigate to.
    - Ensure you first have docker installed. If you do not, head over to https://www.docker.com/ and install docker (it's free!). Ensure the docker daemon is running by opening the application and following any instructions to start the daemon if necessary. 
    - Open your terminal and navigate to root directory of the repo you downloaded, where you should see a `docker-compose.yml` file if you run `ls`. From the same directory just run `docker compose up` and in your terminal you should see some logs such as IPFS (Kubo) starting alongside the Jupyter notebook. You should then be able to access the notebook by visiting http://127.0.0.1:8888 in your browser using the key set within the `docker-compose.yml` file. The default is set to `your_secure_token`. Running via Docker ensures you don't have to worry about conda environments, your python version, package managers etc. To simply install another package make sure to use `uv` by using `!uv pip install`.
- Running on [Github Codespaces](https://docs.github.com/en/codespaces/overview): If you found this repo on github you can simply go over to the Github repo over at https://github.com/dClimate/jupyter-notebooks tap `Code` -> `Codespaces` -> `+ (Create Codespace)`. This will bring you to a page which takes up to a minute to load but you can interact with the deployed container either through an in browser editor (where you can run the cells) or [connect your local VSCode](https://docs.github.com/en/codespaces/developing-in-a-codespace/using-github-codespaces-in-visual-studio-code) to the Jupyter notebook running on Github. Note: Github provides a certain amount of free minutes before they begin to charge
- Deploying on Railway. Railway is a PaaS (Platform as a Service) tool similar to heroku which makes launching apps a breeze. As long as you have an account you can deploy applications using templates without any configuration. What's more is that if your costs remain below $5 a month (which the IPFS notebook does) it remains free! You can find the template to deploy [here](https://railway.com/template/oaqTcv?referralCode=1CR-cB). Tap `deploy now` to get started. Once the deployment has finished and you see a green checkmark visit the URL listed under "deployments", it should be a "****.railway.app" url. If you get an error, wait 30 seconds and refresh. Then use the secure token you set when you deployed the template to login. 

# FAQs

> How do I install more packages?

- Ensure to run `!uv pip install package_name` in the row you wish to install a dependency. As mentioned in the development guide below, uv is used to manage packages instead of plain pip.

> Why should I use this Jupyter notebook?

- Finding GIS data that can be used without any strings attached is usually hard. It is even harder to ensure that it is versioned and immutable so you get git like functionality out of your datasets. The hope is that it "just works". **Learn more about [why](https://blog.dclimate.net/introducing-zarrchitecture-on-dclimate/)**

### Troubleshooting
- You get the error ```ReadTimeout: HTTPConnectionPool(host='0.0.0.0', port=8080): Read timed out. (read timeout=30)```
    - Retry the request by rerunning the cell. Sometimes the connection can time out based on availability of the file due to network topology
    - Ensure that you are using the latest data hashes which can be found [here](https://docs.dclimate.net/) If you're using an old hash which is no longer being indexed by our nodes then the network is unlikely to find it unless it is being hosted elsewhere.It is possible that the hash may have changed since this notebook was written as dClimate is still in flux finalizing its datasets.
    - Ensure you rerun the cell which swarm peers (connects to the other nodes) 
```
!ipfs swarm peering add "/ip4/15.235.14.184/udp/4001/quic-v1/p2p/..."
!ipfs swarm peering add "/ip4/15.235.86.198/udp/4001/quic-v1/p2p/..."
!ipfs swarm peering add "/ip4/148.113.168.50/udp/4001/quic-v1/p2p/..."
```


- Retrievals are going too slow
   - Ensure your internet speed is high enough, not bandwidth constrained, and you do not have ports blocked or have firewalls/vpns which can cause retrieval issues.
   - Check if the dataset you are retrieving data from, conforms to the type of data you are requesting. As all the Zarr data is chunked it needs to be chunked along some dimensions, and the selection of these chunks affects read times. For example, data can be chunked along a wider area (lat x lon) and a shallower time, however if the data you are requesting is for a small area with a deep time you will have to request many chunks, with most of the data (of the surrounding unused lat lons) discarded. In the former case, the dataset you would request, should be optimized for time rather than space (i.e. a dataset with chunks along a smaller lat lon dimension but deeper in time). You can check chunk sizes in xarray with `ds['my_variable'].data.chunks` and read more about it in the [/notebooks/Chunking Explainer.ipynb](/notebooks/Chunking%20Explainer.ipynb)
   - You may notice the warning in your console which says `jupyter-1  | 2025/02/01 05:00:53 failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 7168 kiB, got: 416 kiB). See https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes for details.` This is a result of the fact that this notebook runs inside of a docker container which has a UDP quic buffer limit and as a result performance may be impacted. 
        - For those intellectually curious, learn more  https://discuss.ipfs.tech/t/docker-failed-to-sufficiently-increase-receive-buffer-size/12498/3 and https://github.com/quic-go/quic-go/issues/3801
        - In order to solve this you can try to switch the swarm peer cell to instead connect via `tcp` instead of `quic-v1`
```
!ipfs swarm peering add "/ip4/127.0.0.1/tcp/4001/p2p/<_node1_peer_id_here>"
!ipfs swarm peering add "/ip4/127.0.0.1/tcp/4001/p2p/<node_2_peer_id_here>"
!ipfs swarm peering add "/ip4/127.0.0.1/tcp/4001/p2p/<node_3_peer_id_here>"
```
- This notebook is mostly for prototyping and depending where it's deployed it can be bottlenecked by both network and machine. For massive data analysis and serving up production loads please follow instructions to deploy an IPFS node and directly connect to that node from the notebook replacing the URL `hamt = HAMT(store=IPFSStore(gateway_uri_stem="http://0.0.0.0:8080"), root_node_id=root_cid)` If you are a business, academic institution or another type of organization please reach out to us!

# Development Guide
## Setting Up
This repo uses [uv](https://docs.astral.sh/uv/) for dependency management, Docker for isolating environments (so that nothing is exposed to the machine running the code aside from ports), IPFS within docker for accessing the wider IPFS network, and Jupyter for running python notebooks.

There is a `requirements.txt` file which has base requirements which will exist for all deployments however it currently only has jupyter related requirements.To test any changes simply run `docker compose up` after ensuring to clear out any images or volumes during development which can be left hanging.

The `scripts/start.sh` file ensures all necessary IPFS commands are run. This file can be used for other tooling if needed.


### Upgrading Kubo
In order to upgrade Kubo which at the time of writing is at v0.33.1 you must modify `KUBO_VERSION` in the Dockerfile.jupyter and run:

1. `docker compose down` if already running
2. `docker compose build --no-cache`
3. `docker compose up` to run the most up-to-date version of kubo

# Contributions
- Currently this notebook only fetches from one node at a time, but all the data is essentially a graph that can be retrieved via [divide-and-conquer](https://en.wikipedia.org/wiki/Divide-and-conquer_algorithm) from multiple nodes at once. This was prototyped and explained [here](https://www.youtube.com/watch?v=Cv01ePa0G58) but not completed. We welcome any assistance in this endeavor! 
- We encourage any improvements to existing notebooks or new notebooks which demonstrate an interesting usecase of P2P data :)
