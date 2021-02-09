# Estimating public opinion in developing countries using social media
This project outlines a strategy and its feasibility and limitations in estimating public opinion in English-speaking developing countries. This may have consequences for the idea of political and electoral accountability, the social contract, depending on how our strategy can reliably produce estimates of public opinion. These estimates may serve as a comparison against official electoral results.

## Research design
### How can public Twitter data be used to increase political accountability?

Using Twitter data, I aim to estimate public opinion and investigate to what extent and how these estimates can be used to increase political accountability. 

## Pipeline
1. Data collection: Tweets, covariates, electoral results, survey results, language demographics
2. Tweet analysis:
	* Sentiment analysis: Classifying each Tweet
	* Extracting individual-level covariates (gender, age, location, etc.)
3. Public opinion prediction:
	* Simple favourability proportion (% share who favours a leader over time)
	* Differences by regions, characteristics, events, etc.
	* Rates of change: If overall share is too biased, changes in sentiment may be a better and more reliable predictor
4. Problems
	* Bias of Twitter users: Maybe: Younger, more extreme, more outward-looking, etc. 
	* Bots: How many Tweets does not represent a single person's views? Check research on spotting Twitter bots.

### Get Tweets
`Python`'s [twint](https://github.com/twintproject/twint) module allows us to scrape Tweets in a scalable way. With `R`'s [reticulate](https://rstudio.github.io/reticulate/) package, I call our `Python` function from `R`.

#### Locations within each country
Next focus is being able to gather Tweets from different locations within a country. This can serve to see differences between regions as well as assisting a weighting scheme.
1. Add locations/cities for each country to scraper help data based on what is available in covariate data
2. Scrape tweets for locations in each country

How to decide on coordinates and radius of scraping locations:
Use GPW population count raster data, converted to polygons, to determine scraping locations and radius. With high spatial granularity down to 1 km and data across years (2010, 2015, 2020), these can be used for a consistent way of finding a radius. 
* Seems to have a raster dataset including population by sex and age
* Can add city and other point data to visualise significant cities (data from Africapolis, Global Data Lab).
Considerations:
* Can a GPW polygon cross two countries? GPW4 documentation suggests they cannot because they use international boundaries (p. 5). Some countries were not adjusted (p. 38). Check if those on the border align with those you end up scraping (i.e. does a boundary line go through a polygon?)
* MAUP problem (p. 26), which could be interesting to discuss.
* GWR?

Method:
1. Choose areas to scrape within a country:
	a. Randomly
	b. By one or several variables
		* For example, choose X largest within each subnational region, or X randomly among a subset (e.g. those with a greater population than Y) in each region
2. Discard or include areas that border several countries. Needs to distinguish between a land or water border. Perhaps GPW includes country data?

Use Admin Unit data to choose cities or regions, then use GDP raster data to choose exact locations. For example, choose one region and then select three most populous rasters within that region. Admin Unit data gives valuable covariates. Consider that this needs to be done for several regions for each day. Check out O'Grady's slides on the problems of inferring higher level values to individuals, which would be a necessary evil here.
* Using distance to centroid or being within subnational boundaries. Have contacted Columbia about GPW boundaries. World Bank might also have them.

#### Which countries?
Tentative group: Nigeria, Iraq, Phillipines, Egypt, Tunis, Russia, Turkey, Malaysia, Zimbabwe
Looking at differences in English-speaking proportion, number of Twitter users, electoral corruption and other characteristics, we can discuss the consequences of the accuracy of the Twitter public opinion by country.

* Which cities or locations to choose should considered in light of the available covariate statistics, e.g. income level, education level, and other demographics, as it should be used for weighting.
* Tweets gathered within the radius of city A may not be in city A's country if it is close to a border
https://stackoverflow.com/questions/21708488/get-country-and-continent-from-longitude-and-latitude-point-in-r/21727515

Visualising within-country clusters:
https://gis.stackexchange.com/questions/119736/ggmap-create-circle-symbol-where-radius-represents-distance-miles-or-km
https://stackoverflow.com/questions/34183049/plot-circle-with-a-certain-radius-around-point-on-a-map-in-ggplot2
https://gis.stackexchange.com/questions/282750/identify-polygon-containing-point-with-r-sf-package

#### Rotating proxies: Robin Hood method:
If Twitter blocks my IP, it may be necessary to automatically change IP proxies throughout the scraping of Tweets. A VPN may help with this as well. Otherwise, a proxy service may be required.

### Sentiment analysis
https://www.tidytextmining.com/index.html

### Individual-level characteristics
* Age, race, gender: https://github.com/wri/demographic-identifier

## Data
### Twitter
* Tweets from [Twitter's API](https://developer.twitter.com/en/docs)
### Control and comparison
* Electoral data
* Traditional polling results
### Scraping help data
* Country leaders data, [REIGN](https://oefdatascience.github.io/REIGN.github.io/menu/reign_current.html)
### Spatial
* GDL shapefiles: https://globaldatalab.org/shdi/shapefiles/
* Africapolis, database of thousands of cities in Africa: https://africapolis.org/data
* Natural Earth, https://www.naturalearthdata.com/downloads/50m-cultural-vectors/
* World Bank, boundaries: https://datacatalog.worldbank.org/dataset/world-bank-official-boundaries/resource/e2ced400-e63e-415b-9c4d-8138fdc21bb0, https://datacatalog.worldbank.org/dataset/world-subnational-boundaries, https://datacatalog.worldbank.org/dataset/world-bank-official-boundaries
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
