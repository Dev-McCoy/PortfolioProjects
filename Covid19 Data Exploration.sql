--To view the Covid19 Death Table
SELECT *
FROM PorfolioProjects..CovidDeaths;

--To view the Covid19 Vaccination Table
SELECT *
FROM PorfolioProjects..CovidVaccinations;

--To calculate Global Covid-19 Incidence and Mortality
SELECT SUM(new_cases) AS global_cases, 
	   SUM(CAST(new_deaths AS INT)) AS global_deaths
FROM PorfolioProjects..CovidDeaths


-- To find the country with the highest COVID-19 Incidence Proportion (Risk)
SELECT location, 
	   population, 
	   MAX(CAST(total_cases AS INT)) AS total_cases,
	   ROUND(MAX(total_cases/population) * 100, 2) AS incidence_proportion
FROM PorfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY incidence_proportion DESC

--To find the continent with the highest Covid-19 mortality rate
SELECT continent, 
		(total_death_count/total_pop)* 1000 AS mortality_rate
FROM(
	SELECT continent, 
	MAX(CAST(total_deaths AS INT)) AS total_death_count, 
	MAX(population ) AS total_pop
	FROM PorfolioProjects..CovidDeaths
		WHERE continent IS NOT NULL
		GROUP BY continent) AS subquery
ORDER BY mortality_rate DESC

--To find the country with the highest Covid-19 mortality rate
SELECT location,
	  (total_death_count/total_pop)* 1000 AS mortality_rate
FROM(
	SELECT location,
		   MAX(CAST(total_deaths AS INT)) AS total_death_count,
	       MAX(population ) AS total_pop
	FROM PorfolioProjects..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location) AS subquery
ORDER BY mortality_rate DESC


--To calculate the rolling percentage of the population vaccinated in Canada

WITH popvac (continent, location, date, population, new_vaccinations, rolling_people_vac)
AS (
SELECT deaths.continent, 
	   deaths.location, 
	   deaths.date, 
	   deaths.population, 
	   Vaccinations.new_vaccinations,
	   SUM(CAST(Vaccinations.new_vaccinations AS bigint)) 
	   OVER (Partition by Deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vac
FROM PorfolioProjects..CovidDeaths AS deaths
JOIN PorfolioProjects..CovidVaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location 
	AND deaths.date = Vaccinations.date
WHERE deaths.continent IS NOT NULL)

SELECT *, (rolling_people_vac/population) * 100 AS vacc_rate
FROM popvac
WHERE location LIKE '%Canada%'


--To look at the relationship between vaccination and gdp at the continent level

DROP TABLE IF EXISTS #covid_vs_economy
CREATE TABLE #covid_Vs_Economy
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vac numeric,
gdp_per_capita numeric
)

INSERT INTO #covid_Vs_Economy
SELECT  deaths.continent,
	   deaths.location, 
	   deaths.date, 
	   deaths.population, 
	   Vaccinations.new_vaccinations,
	   SUM(CAST(Vaccinations.new_vaccinations AS bigint)) 
	   OVER (Partition by Deaths.location ORDER BY deaths.location, deaths.date) AS rolling_people_vac,
	   gdp_per_capita
FROM PorfolioProjects..CovidDeaths AS deaths
JOIN PorfolioProjects..CovidVaccinations AS Vaccinations
	ON deaths.location = Vaccinations.location 
	AND deaths.date = Vaccinations.date
WHERE deaths.continent IS NOT NULL


SELECT continent, ROUND((MAX(rolling_people_vac)/MAX(population)*100),2,1) AS total_vac, ROUND(AVG(gdp_per_capita),2,1) AS avg_gdp
FROM #covid_Vs_Economy
GROUP BY continent
ORDER BY total_vac DESC

-- To create view to store data for visualization

CREATE VIEW	covid_risk AS
SELECT location, 
	   population, 
	   MAX(CAST(total_cases AS INT)) AS total_cases,
	   ROUND(MAX(total_cases/population) * 100, 2) AS incidence_proportion
FROM PorfolioProjects..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population 

SELECT*
FROM covid_risk