# Estimating public opinion in developing countries using social media
This project outlines a strategy and its feasibility and limitations in estimating public opinion in English-speaking developing countries. This may have consequences for the idea of political and electoral accountability, the social contract, depending on how our strategy can reliably produce estimates of public opinion. These estimates may serve as a comparison against official electoral results.

## Research design
### How can public Twitter data be used to increase political accountability?

Using Twitter data, I aim to estimate public opinion and investigate to what extent and how these estimates can be used to increase political accountability. Countries 

## Data
### Twitter
* Tweets from [Twitter's API](https://developer.twitter.com/en/docs)
* Country leaders data, [REIGN](https://oefdatascience.github.io/REIGN.github.io/menu/reign_current.html)
### Control and comparison
* Electoral data
* Traditional polling results
### Supplementary, covariates and weights
* English speaking population: [Population by language, sex and urban/rural residence, UN](http://data.un.org/Data.aspx?d=POP&f=tableCode:27)
	https://en.wikipedia.org/wiki/List_of_countries_by_English-speaking_population
* Corruption index: [Transparency International](https://www.transparency.org/en/cpi/2020/index/nzl)
* Country populations: [UN population statistics](https://population.un.org/wpp/Download/Standard/CSV/)
* Twitter user demographics
	https://www.businessofapps.com/data/twitter-statistics/
	Hootsuite
	https://www.arabsocialmediareport.com/home/index.aspx

## Pipeline
1. Data collection: Tweets, covariates, electoral results, survey results, language demographics
2. Tweet analysis:
	* Sentiment analysis: Classifying each Tweet
	* Extracting individual-level covariates (gender, age, location, etc.)
3. Public opinion prediction:
	* Simple favourability proportion
	* Differences by regions, characteristics, events
	* Rates of change
4. Problems
	* Bias of Twitter users: Maybe: Younger, more extreme, more outward-looking, etc. 
	* Bots: How many Tweets does not represent a single person's views? Check research on spotting bots.

### Data collection
#### Get Tweets
`Python`'s `twint` module allows us to scrape Tweets in a scalable way. With `R`'s `reticulate` package, I call our `Python` function from `R`.
* https://rstudio.github.io/reticulate/
* https://github.com/twintproject/twint

##### Different locations within a country
Next focus is being able to gather Tweets from different locations within a country. This can serve to see differences between regions as well as assisting a weighting scheme.

Visualising within-country clusters:
https://gis.stackexchange.com/questions/119736/ggmap-create-circle-symbol-where-radius-represents-distance-miles-or-km
https://stackoverflow.com/questions/34183049/plot-circle-with-a-certain-radius-around-point-on-a-map-in-ggplot2

##### Rotating proxies: Robin Hood method:
If Twitter blocks the scraping, it may be necessary to automatically change IP proxies at some step or time.

### Sentiment analysis
https://www.tidytextmining.com/index.html

## Which countries?
Using several factors, I choose which countries to investigate:
1. Languages spoken: For this project, I limit by research to English-speaking countries
2. Number of Twitter users
3. Electoral corruption
