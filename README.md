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
4. Problems!
* Bias of Twitter users: Maybe: Younger, more extreme, more outward-looking, etc. 
* Bots: How many Tweets does not represent a single person's views? Check research on spotting bots.

### Data collection
#### Get Tweets
Use Python's twint module.
https://rstudio.github.io/reticulate/
https://stackoverflow.com/questions/52526092/passing-r-variables-to-a-python-script-with-reticulate
https://stackoverflow.com/questions/41638558/how-to-call-python-script-from-r-with-arguments/45908913
https://github.com/twintproject/twint

* Use geocodes to search for Tweets in different places each day, which may be helpful for a weight scheme

Use AWS? https://aws.amazon.com/blogs/opensource/getting-started-with-r-on-amazon-web-services/

Rotating proxies: Robin Hood method:
https://free-proxy-list.net/
https://www.scrapehero.com/how-to-rotate-proxies-and-ip-addresses-using-python-3/

### Sentiment analysis
https://www.tidytextmining.com/index.html

## Which countries?
Using several factors, I choose which countries to investigate:
1. Languages spoken: For this project, I limit by research to English-speaking countries
2. Number of Twitter users
2. Electoral corruption

## Problems!
* Bias of Twitter users: Maybe: Younger, more extreme, more outward-looking, etc. 
* Bots: How many Tweets does not represent a single person's views? Check research on spotting bots.