# Estimating public opinion in developing countries using social media
This project outlines a strategy and its feasibility and limitations in estimating public opinion in English-speaking developing countries. This may have consequences for the idea of political and electoral accountability, the social contract, depending on how our strategy can reliably produce estimates of public opinion. These estimates may serve as a comparison against official electoral results.

This is my undergraduate dissertation at UCL.

The final product will be an R package to promote open-source, scalable research.

### To-do:
* Train data
* Events data to explain or validate changes in public opinion (qualitative/visual validation), use Wikipedia, eg https://en.wikipedia.org/wiki/2019_in_Nigeria
* Any traditional polling available? (A consideration when adding new countries)
* Add other countries, including developed countries for comparison
* Translate non-English tweets? (Lucas et al 2015; de Vries, Schoonevelde and Schumacher 2018)

### Download analysis as a package:
```
library(devtools)
devtools::install_github("williamrohdemadsen/dev-public-opinion", build_vignettes = TRUE)
library(devpublicopinion)
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
`Python`'s [twint](https://github.com/twintproject/twint) module allows us to collect Tweets in a scalable way. With `R`'s [reticulate](https://rstudio.github.io/reticulate/) package, I run our `Python` script from `R`.

The Python module `multiprocessing` allows us to cut down on time spent getting tweets. It runs collections in parallel, utilising multiple threads on your computer. The Python script is sourced from R, but it is not run within R using `reticulate` as that R package does not allow for multiprocessing.

For now, I use the `Pool` method of `multiprocessing` rather than `Process`. I have not tested which is quicker.

This issue may be I/O bound, so it may make sense to use more threads than is available. This [article](https://www.freecodecamp.org/news/multiprocessing-vs-multithreading-in-python-what-you-need-to-know-ef6bdc13d018/) suggests that multithreading may be better since the task is I/O heavy. That might mean I need to look into using the `threading` module.

Difference between getting tweets one-a-day or over multiple days. Collecting "Buhari" during the first two weeks of January 2015..
1. `per 1 day, threads = 7`: 351.08 seconds (188 mb), which is 0,54 mb per second
2. `per 2 days, threads = 7`: 457.49 seconds (222 mb), which is 0,49 mb per second
3. `per 7 days, threads = 7`: 1301.32 seconds (266 mb, since 7-day-periods stretched beyond)
4. `per 1 day, threads = 14`: 296.17 seconds (201 mb)
5. `per 1 day, threads = 30`: 300.39 seconds (201 mb)
6. `per 12 hours, threads = 14`: 287.37 seconds (118 mb)
7. `per 12 hours, threads = 30`: 286.12 seconds (118 mb)

Imposing `limit = 20000` (per 12 hours) on the 6th scenario above, cuts the time to 199.5 seconds while only reducing tweets to 116 mb. `limit = 10000` cuts it to 104.68 seconds and 102 mb. Note that the `limit` in the 6th scenario refers to number of tweets per 12-hour-interval. `limit = 5000` cuts it to 54.8 seconds and 61 mb. These are for non-geocoded tweets.

A takeaway may to impose a limit on non-geocoded tweets to save time and gather geocodes tweets, which have less volume, without a limit.

Tweets are collected by two methods:
1. Tweets which mention a leader
2. Tweets which mention a leader and give coordinates with the smallest-possible circle of a country

#### Which countries?
Tentative group: Nigeria, Iraq, Phillippines, Egypt, Tunis, Russia, Turkey, Malaysia, Zimbabwe, Afghanistan, Mozambique
Looking at differences in English-speaking proportion, number of Twitter users, electoral corruption and other characteristics, we can discuss the consequences of the accuracy of the Twitter public opinion by country.

#### Rotating proxies: Robin Hood method:
It may be necessary to automatically change IP proxies during the collection. A VPN seems to work fine. Otherwise, a proxy service may be required.

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
* Georgia: https://www.ndi.org/publications/results-june-2017-public-opinion-polls-georgia

### Election
* CLEA: http://www.electiondataarchive.org/data-and-documentation.php
* Afghanistan, Presidential: https://afghanistanelectiondata.org/, https://github.com/nditech/af-elections-data
* Nigeria, Presidential: Stears: https://nigeriaelections.stearsng.com/president/2019 (confirm data's accuracy against Reuters?)
* Pakistan, General Assembly: https://github.com/colincookman/pakistan_elections
* Egypt: [Presidential 2018](https://pres2018.elections.eg/results-2018), [Presidential 2014](https://pres2014.elections.eg/presidential-elections-2014-results), [Presidential 2012](http://pres2012.elections.eg/round2-results)
	* https://github.com/p-mohamed-elsawy/subdivisions-of-egypt/blob/master/data.json?
* Georgia: https://github.com/ForSetGeorgia/Georgian-Election-Data
	
NDI results: https://www.ndi.org/search?query=results

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
* Geoboundaries: https://www.geoboundaries.org/index.html#getdata
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
