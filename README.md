# Estimating public opinion in developing countries using Twitter data
This project outlines a data-driven strategy and its feasibility and limitations in estimating public opinion in English-speaking developing countries.

This may have consequences for the idea of political and electoral accountability, the social contract, depending on how our strategy can reliably produce estimates of public opinion. These estimates may serve as a comparison against official electoral results.

This is my thesis at UCL.

To reproduce my analysis and pipeline, you can download my R package. It was created to help promote open-source, scalable research.

### Download analysis as a package:
```
library(devtools)
devtools::install_github("williamrohdemadsen/dev-public-opinion", build_vignettes = TRUE)
library(devpublicopinion)
```

## Pipeline
1. Data collection: Tweets, covariates, electoral results, survey results, and language demographics
2. Tweet analysis:
	* Sentiment analysis
	* Higher and lower level covariates
3. Public opinion prediction
	* Machine learning with training and validation data
	* Multilevel regression with post-stratification
4. Validation
	* Election data
	* Events data
	* Differences by regions, characteristics, events, etc.

### Get Tweets
`Python`'s [twint](https://github.com/twintproject/twint) module allows us to collect Tweets in a scalable way. With `R`'s [reticulate](https://rstudio.github.io/reticulate/) package, I run our `Python` script from `R`.

The Python module `multiprocessing` allows us to cut down on time spent getting tweets. It runs collections in parallel, utilising multiple threads on your computer. The Python script is sourced from R, but it is not run within R using `reticulate` as that R package does not allow for multiprocessing.

For now, I use the `Pool` method of `multiprocessing` rather than `Process`. I have not tested which is quicker.

This issue may be I/O bound, so it may make sense to use more threads than is available. This [article](https://www.freecodecamp.org/news/multiprocessing-vs-multithreading-in-python-what-you-need-to-know-ef6bdc13d018/) suggests that multithreading may be better since the task is I/O heavy. That might mean I need to look into using the `threading` module.

Difference between getting tweets one each day or over multiple days. Collecting "Buhari" during the first two weeks of January 2015:
1. `per 1 day, threads = 7`: 351.08 seconds (188 MB), which is 0,54 MB per second
2. `per 2 days, threads = 7`: 457.49 seconds (222 MB), which is 0,49 MB per second
3. `per 7 days, threads = 7`: 1301.32 seconds (266 MB, since 7-day-periods stretched beyond)
4. `per 1 day, threads = 14`: 296.17 seconds (201 MB)
5. `per 1 day, threads = 30`: 300.39 seconds (201 MB)
6. `per 12 hours, threads = 14`: 287.37 seconds (118 MB)
7. `per 12 hours, threads = 30`: 286.12 seconds (118 MB)

Imposing `limit = 20000` (per 12 hours) on the 6th scenario cuts the time to 199.5 seconds while only reducing tweets to 116 MB. `limit = 10000` cuts it to 104.68 seconds and 102 MB. Note that the `limit` in the 6th scenario refers to the number of tweets per 12-hour-interval. `limit = 5000` cuts it to 54.8 seconds and 61 MB. These are for non-geocoded tweets.

A takeaway may be to impose a limit on non-geocoded tweets to save time and gather geocodes tweets, which have less volume, without a limit.

#### Which countries?
Group: Nigeria, Zimbabwe, Afghanistan, Mozambique, and Georgia.
Differences in English-speaking proportion, number of Twitter users, electoral corruption and other characteristics can affect the accuracy of Twitter-based public opinion predictions.

#### Rotating proxies: Robin Hood method:
It may be necessary to automatically change IP proxies during the collection.

### Text analysis

The following resources were either used or considered during the text analysis:
* Tidy Text: https://www.tidytextmining.com/index.html
* tokenizers package: https://cran.r-project.org/web/packages/tokenizers/index.html

### Individual-level characteristics
* Age, race, gender: https://github.com/wri/demographic-identifier

* Gender: Use census date for each country. Liu and Ruths' (2013) gender-name association score between -1 to 1 could work.
http://www.namepedia.org/en/firstname/

### Comparison and validation
Depends on what is available for each country. For example, if a country's official election results are not reliable, there are other sources to look at, such as polling or election complaints.

* Elections complaints: Validation could also be done for certain countries if they publish data on election complaints. One hypothesis could revolve around a positive correlation between the difference of the official election vote rate and the Twitter prediction against the number of complaints. Afghanistan publishes data on complaints.

* Compare against a country with rich polling data, e.g. US or UK.

#### Afghanistan:
About the 2019 election, "Saturday’s vote was marred by violence, Taliban threats and widespread allegations of mismanagement and abuse" by [Gannon](https://globalnews.ca/news/5966475/afghanistan-election-political-chaos/). Investigate if predictions can somehow be validated by comparing to province-level death tolls, Taliban control.

Compare with electoral complaints on province-level.

## Data
### Twitter
* Tweets from [Twitter's API](https://developer.twitter.com/en/docs)

### Polling
* Europe Elects: https://europeelects.eu/data/
* Asia Foundation, Afghanistan surveys: https://asiafoundation.org/where-we-work/afghanistan/survey/download-data-form/
* Global Barometer Surveys, Waves 1-3: https://www.globalbarometer.net/survey_sc
* Pew, Global Attitudes: https://www.pewresearch.org/global/datasets/
* Check Wikipedia election pages
* https://libguides.princeton.edu/politics/opinion/international
* Georgia: https://www.ndi.org/publications/results-june-2017-public-opinion-polls-georgia
* Mexico: https://www.ine.mx/memoria-historica-la-regulacion-encuestas-electorales-sondeos-opinion-mexico/
* Zimbabwe: https://ewn.co.za/2018/07/20/survey-mnangagwa-and-chamisa-neck-and-neck-in-zim-presidential-race; http://www.zesn.org.zw/wp-content/uploads/2018/08/ZESN%E2%80%99s-Presidential-Results-Projection-from-Sample-Based-Observation.pdf
* United States (for comparison), The Economist: https://github.com/TheEconomist/us-potus-model; https://projects.fivethirtyeight.com/polls/; https://gist.github.com/elliottmorris/8775a074deffbfc5a9be098e754a5167

### Election
* CLEA: http://www.electiondataarchive.org/data-and-documentation.php
* Afghanistan, Presidential: https://afghanistanelectiondata.org/, https://github.com/nditech/af-elections-data
* Nigeria, Presidential: Stears: https://nigeriaelections.stearsng.com/president/2019 (confirm data's accuracy against Reuters?)
* Pakistan, General Assembly: https://github.com/colincookman/pakistan_elections
* Egypt: [Presidential 2018](https://pres2018.elections.eg/results-2018), [Presidential 2014](https://pres2014.elections.eg/presidential-elections-2014-results), [Presidential 2012](http://pres2012.elections.eg/round2-results)
	* https://github.com/p-mohamed-elsawy/subdivisions-of-egypt/blob/master/data.json?
* Georgia: https://github.com/ForSetGeorgia/Georgian-Election-Data; https://data.electionsportal.ge/en/data_archives
* Mexico: https://computos2018.ine.mx/#/presidencia/nacional/1/1/1/1; http://siceef.ine.mx/downloadDB.html#; https://github.com/emagar/elecRetrns/tree/master/data; http://siceef.ine.mx/atlas.html?p%C3%A1gina=1&perPage=1000#siceen
* Zimbabwe: https://github.com/dwillis/zimbabwe-election-results; https://www.zec.org.zw/pages/2018_Presidential#; https://github.com/tichmangono/zimbabweelection2018_analysis; https://en.wikipedia.org/wiki/2018_Zimbabwean_general_election
	
NDI results: https://www.ndi.org/search?query=results

### Leader data
* Country leaders data, [REIGN](https://oefdatascience.github.io/REIGN.github.io/menu/reign_current.html)

### Spatial
* GDL shapefiles: https://globaldatalab.org/shdi/shapefiles/
* Africapolis, a database of thousands of cities in Africa: https://africapolis.org/data
* World Cities, https://hub.arcgis.com/datasets/6996f03a1b364dbab4008d99380370ed_0
* Natural Earth, urban LandScan: https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-populated-places/
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
