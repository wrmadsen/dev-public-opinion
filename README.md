# Estimating public opinion in developing countries using social media
This project outlines a strategy and its feasibility and limitations in estimating public opinion in English-speaking developing countries. This may have consequences for the idea of political and electoral accountability, the social contract, depending on how our strategy can reliably produce estimates of public opinion. These estimates may serve as a comparison against official electoral results.

### To-do:
* Double-check spatial projections
* Check leader names, tidy (issue with family names)
* Events data to explain or validate changes in public opinion (qualitative/visual validation)

### Download analysis as a package:
```
library(devtools)
devtools::install_github("williamrohdemadsen/dev-public-opinion", build_vignettes = TRUE, auth_token =  " 76ec7fb0f2100d8fd7c3c340c4719ff70620a125")
```

## Research design
### How can public Twitter data be used to increase political accountability?

Using Twitter data, I aim to estimate public opinion and investigate to what extent and how these estimates can be used to increase political accountability. 

## Hypotheses
* A model using region-level differences will have a higher accuracy than a model using only individual covariates? What is it validated against?

## Pipeline
1. Data collection: Tweets, covariates, electoral results, survey results, language demographics
2. Tweet analysis:
	* Sentiment analysis: Classifying each Tweet
	* Extracting individual-level covariates (gender, age, location, etc.)
3. Public opinion prediction: Simple favourability proportion (% share who favours a leader over time)
	* Machine learning with training data in the form of election data and other sources
	* MRP
	* Census-weighting: Population, internet use, 
4. Validation
	* Election data
	* Events data
	* Differences by regions, characteristics, events, etc.
	* Rates of change: If overall share is too biased, changes in sentiment may be a better and more reliable predictor
5. Problems
	* Bias of Twitter users: Maybe: Younger, more extreme, more outward-looking, etc. 
	* Bots: How many Tweets does not represent a single person's views? Check research on spotting Twitter bots.

### Get Tweets
`Python`'s [twint](https://github.com/twintproject/twint) module allows us to scrape Tweets in a scalable way. With `R`'s [reticulate](https://rstudio.github.io/reticulate/) package, I call our `Python` function from `R`.

Tweets are scraped by two methods:
	1. Tweets which mention a leader
	2. Tweets which mention a leader and give coordinates with the smallest-possible circle of a country

#### Which countries?
Tentative group: Nigeria, Iraq, Phillipines, Egypt, Tunis, Russia, Turkey, Malaysia, Zimbabwe, Afghanistan
Looking at differences in English-speaking proportion, number of Twitter users, electoral corruption and other characteristics, we can discuss the consequences of the accuracy of the Twitter public opinion by country.

#### Rotating proxies: Robin Hood method:
If Twitter blocks my IP, it may be necessary to automatically change IP proxies throughout the scraping of Tweets. A VPN may help with this as well. Otherwise, a proxy service may be required.

### Text analysis

The following resources were either used or considered during the text analysis:
* Tidy Text: https://www.tidytextmining.com/index.html
* tokenizers package: https://cran.r-project.org/web/packages/tokenizers/index.html

### Individual-level characteristics
* Age, race, gender: https://github.com/wri/demographic-identifier

* Age:

* Gender: Use census date for each country. Liu and Ruths' (2013) gender-name association score between -1 to 1 could work.
http://www.namepedia.org/en/firstname/

### Comparison and validation
Depends on what is available for each country. For example, if a country's official election results are not reliable, there are other sources to look at, such as polling, election complaints or other.

* Elections complaints: Validation could also be done for certain countries if they publish data on election complaints. One hypothesis could revolve around a positive correlation between the difference of the official election vote rate and the Twitter prediction against the number of complaints. Afghanistan publishes data on complaints.

* Compare against country with rich polling data, e.g. US or UK.

#### Afghanistan:
About 2019 election, "Saturday’s vote was marred by violence, Taliban threats and widespread allegations of mismanagement and abuse" by [Gannon](https://globalnews.ca/news/5966475/afghanistan-election-political-chaos/). Investigate if predictions can somehow be validated by comparing to province-level death tolls, Taliban control.

Compare with electoral complaints on province-level.

#### Nigeria


## Data
### Twitter
* Tweets from [Twitter's API](https://developer.twitter.com/en/docs)
### Surveys
* Europe Elects: https://europeelects.eu/data/
* Asia Foundation, Afghanistan surveys: https://asiafoundation.org/where-we-work/afghanistan/survey/download-data-form/
* Global Barometer Surveys, Waves 1-3: https://www.globalbarometer.net/survey_sc
* Pew, Global Attitudes: https://www.pewresearch.org/global/datasets/
* Check Wikipedia election pages
* https://libguides.princeton.edu/politics/opinion/international
### Election
* CLEA: http://www.electiondataarchive.org/data-and-documentation.php
* Afghanistan, Presidential: https://afghanistanelectiondata.org/, https://github.com/nditech/af-elections-data
* Nigeria, Presidential: Stears: https://nigeriaelections.stearsng.com/president/2019 (confirm data's accuracy against Reuters?)
* Pakistan, General Assembly: https://github.com/colincookman/pakistan_elections
### Leader data
* Country leaders data, [REIGN](https://oefdatascience.github.io/REIGN.github.io/menu/reign_current.html)
### Spatial
* GDL shapefiles: https://globaldatalab.org/shdi/shapefiles/
* Africapolis, database of thousands of cities in Africa: https://africapolis.org/data
* World Cities, https://hub.arcgis.com/datasets/6996f03a1b364dbab4008d99380370ed_0
* Natural Earth, urban landscan: https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-populated-places/
* NASA, night light: https://earthobservatory.nasa.gov/features/NightLights/page3.php
* Oak Ridge, landscan: https://landscan.ornl.gov/
### Subnational boundaries
* OCHA: https://data.humdata.org/search?q=subnational&ext_search_source=main-nav
* GADM: https://gadm.org/index.html
* Pakistani constituencies: https://data.humdata.org/dataset/national-constituency-boundaries-pakistan
### Subnational
* Population: http://data.un.org/Data.aspx?d=POP&f=tableCode:240#POP
* Population: https://stats.oecd.org/Index.aspx?Datasetcode=CITIES
* Housing unit types and internet access: http://data.un.org/Data.aspx?d=POP&f=tableCode%3a307
* Water supply system: http://data.un.org/Data.aspx?d=POP&f=tableCode%3a283
* Toilet type: http://data.un.org/Data.aspx?d=POP&f=tableCode%3a287
* Global Data Lab: https://globaldatalab.org/
### Region-level
* Global Subnational Infant Mortality Rates: https://sedac.ciesin.columbia.edu/data/set/povmap-global-subnational-infant-mortality-rates-v2
* Gridded Population of the World (GPW), Administrative Unit: https://sedac.ciesin.columbia.edu/data/set/gpw-v4-admin-unit-center-points-population-estimates-rev11/data-download
### Development
* IPC: Food insecurity: http://www.ipcinfo.org/ipc-country-analysis/population-tracking-tool/en/
* English speaking population: [Population by language, sex and urban/rural residence, UN](http://data.un.org/Data.aspx?d=POP&f=tableCode:27)
* Corruption index: [Transparency International](https://www.transparency.org/en/cpi/2020/index/nzl)
* Perceptions of Electoral Integrity: https://dataverse.harvard.edu/dataverse/PEI
* Country populations: [UN population statistics](https://population.un.org/wpp/Download/Standard/CSV/)
* ITU: Internet data: https://www.itu.int/en/ITU-D/Statistics/Pages/default.aspx
* OECD, Aid finance: https://www.oecd.org/dac/financing-sustainable-development/development-finance-data/
### Regime
* Worldwide Governance Indicators (WGI): http://info.worldbank.org/governance/wgi/#home
* Geddes, Wright, and Frantz’ autocratic regimes dataset (events, etc.): https://sites.psu.edu/dictators/
### National services
* Nigeria: https://nigerianstat.gov.ng/, https://nigeria.opendataforafrica.org/
### Other
* Digital 2020 reports, Hootsuite, https://datareportal.com/reports/
* Twitter MAU, selected countries: https://www.businessofapps.com/data/twitter-statistics/ (Hootsuite/We Are Social)
* https://www.arabsocialmediareport.com/home/index.aspx
* https://investor.twitterinc.com/financial-information/quarterly-results/default.aspx
### Not used currently
* World Bank, boundaries: https://datacatalog.worldbank.org/dataset/world-bank-official-boundaries/resource/e2ced400-e63e-415b-9c4d-8138fdc21bb0, https://datacatalog.worldbank.org/dataset/world-subnational-boundaries, https://datacatalog.worldbank.org/dataset/world-bank-official-boundaries
* Natural Earth, https://www.naturalearthdata.com/downloads/50m-cultural-vectors/
