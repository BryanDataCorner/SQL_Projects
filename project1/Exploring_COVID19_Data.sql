/*
COVID 19 DATA EXPLORATION

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating views, Converting Data Types 
*/


-- Query to show the full content of the covid_deaths and covid_vaccinations tables, ordered by location and date
-- Note: Both tables have columns for iso_code, continent, location, and date, which will allow us to join them later in the analysis.
SELECT *
FROM PortfolioProject1.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

SELECT *
FROM PortfolioProject1.dbo.CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY location, date





-- LOOKING AT TOTAL CASES vs TOTAL DEATHS
-- Calculates the death percentage (total deaths divided by total cases) for each COUNTRY and displays the results in descending order of total cases.
-- Data can be verified against the World Health Organization's COVID-19 Dashboard: https://covid19.who.int/
SELECT Location
	, MAX(CAStotal_deaths AS float)) AS Total_Deaths
	, MAX(CAST(total_cases AST( float)) AS Total_Cases
	, CASE
		WHEN MAX(CAST(total_cases AS float)) = 0 THEN 0
		ELSE MAX(CAST(total_deaths AS float)) / MAX(CAST(total_cases AS float)) * 100 
	  END AS Death_Percentage
FROM PortfolioProject1.dbo.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY location
ORDER BY Total_Cases DESC





-- LOOKING AT GDP vs TOTAL CASES and TOTAL DEATHS
-- Compares the GDP of each country to their total number of deaths and cases
SELECT death.location
	, vaccine.gdp_per_capita AS GDP 
	, MAX(CAST(death.total_deaths AS float)) AS Total_Deaths
	, MAX(CAST(death.total_cases AS float)) AS Total_Cases
	, CASE
		WHEN MAX(CAST(death.total_cases AS float)) = 0 THEN 0
		ELSE MAX(CAST(death.total_deaths AS float)) / MAX(CAST(total_cases AS float)) * 100 
	  END AS Death_Percentage
FROM PortfolioProject1.dbo.CovidDeaths AS death
		INNER JOIN PortfolioProject1.dbo.CovidVaccinations AS vaccine
			ON death.location = vaccine.location
			AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
GROUP BY death.location, vaccine.gdp_per_capita
ORDER BY Total_Cases DESC





-- LOOKING AT TOTAL CASES & TOTAL DEATHS vs POPULATION
-- Calculates the total number of cases and deaths for each location and their corresponding population.
-- Shows what percentage of the population was infected and died due to COVID-19.
SELECT Location
	, Population
	, MAX(CAST(total_cases AS float)) AS Total_Cases
	, MAX(CAST(total_cases AS float)) / population * 100 AS Population_Infected_Percentage
	, MAX(CAST(total_deaths AS float)) AS Total_Deaths
	, MAX(CAST(total_deaths AS float)) / population * 100 AS Population_Death_Percentage
FROM PortfolioProject1.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY population DESC





-- BREAKING THINGS DOWN BY CONTINENT
-- Calculates the total number of deaths due to COVID-19 for each continent.
SELECT Location
	, SUM(CAST(new_deaths AS float)) AS Total_Deaths
	, SUM(CAST(new_cases AS float)) AS Total_Cases
FROM PortfolioProject1.dbo.CovidDeaths	
WHERE continent IS NULL
GROUP BY Location
ORDER BY Total_Cases DESC





-- WORLDWIDE NUMBERS
-- Calculates the total number of cases and deaths worldwide, and the corresponding death percentage.
SELECT location
	, SUM(CAST(new_deaths AS float)) AS Total_Deaths
	, SUM(CAST(new_cases AS float)) AS Total_Cases
FROM PortfolioProject1.dbo.CovidDeaths	
WHERE continent IS NULL AND location LIKE '%world%'
GROUP BY location
ORDER BY Total_Cases DESC





-- TIME SERIES ANALYSIS
-- Total Population VS Vaccination
-- Using CTE
WITH PopulationVSVaccination
	(Continent
	, Location
	, Date
	, Population
	, new_vaccinations
	, RollingCount_PeopleVacinated)
		AS
		(
		SELECT death.continent
			, death.location
			, death.date
			, death.population
			, new_vaccinations
			, SUM(CAST(vaccine.new_vaccinations AS bigint)) OVER (
			      PARTITION BY death.location
				  ORDER BY death.location
					  , death.date
			 		  ) AS RollingCount_PeopleVacinated
		FROM PortfolioProject1.dbo.CovidDeaths AS death
		INNER JOIN PortfolioProject1.dbo.CovidVaccinations AS vaccine
			ON death.location = vaccine.location
			AND death.date = vaccine.date
		WHERE death.continent IS NOT NULL
		)
SELECT *
	, RollingCount_PeopleVacinated / population * 100 AS Percent_People_Vaccinated
FROM PopulationVSVaccination
ORDER BY location, date;





-- TIME SERIES ANALYSIS _ EXTENDED
-- Includes vaccinations, cases, and deaths
-- Using Temp Table
DROP TABLE IF EXISTS #TimeSeriesAnalysis
CREATE TABLE #TimeSeriesAnalysis
	(
	continent nvarchar(255)
	, location nvarchar(255)
	, date datetime
	, population numeric
	, new_vaccinations numeric
	, new_deaths numeric
	, new_cases numeric
	, RollingCount_PeopleVaccinated numeric
	, RollingCount_Deaths numeric
	, RollingCount_Cases numeric
	)

INSERT INTO #TimeSeriesAnalysis
SELECT death.continent
	, death.location
	, death.date
	, death.population
	, vaccine.new_vaccinations
	, death.new_deaths
	, death.new_cases
	, SUM(CAST(vaccine.new_vaccinations as bigint)) OVER (
		PARTITION BY death.location
		ORDER BY death.location
			, death.date
		) AS RollingCount_PeopleVaccinated
	, SUM(CAST(death.new_deaths as bigint)) OVER (
		PARTITION BY death.location
		ORDER BY death.location
			, death.date
		) AS RollingCount_Deaths
	, SUM(CAST(death.new_cases as bigint)) OVER (
		PARTITION BY death.location
		ORDER BY death.location
			, death.date
		) AS RollingCount_Cases
FROM PortfolioProject1.dbo.CovidDeaths AS death
	INNER JOIN PortfolioProject1.dbo.CovidVaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date
WHERE death.continent IS NOT NULL

SELECT *
	, (RollingCount_PeopleVaccinated / population * 100) AS Percent_People_Vaccinated
	, (RollingCount_Deaths / population * 100) AS Percent_Covid_Deaths
	, (RollingCount_Cases / population * 100) AS Percent_Covid_Cases
FROM #TimeSeriesAnalysis
ORDER BY location, date





-- CREATING VIEW FOR FUTURE VISUALIZATION
CREATE VIEW TimeSeriesAnalysis AS
SELECT death.continent
	, death.location
	, death.date
	, death.population
	, vaccine.new_vaccinations
	, death.new_deaths
	, death.new_cases
	, SUM(CAST(vaccine.new_vaccinations as bigint)) OVER (
		PARTITION BY death.location
		ORDER BY death.location
			, death.date
		) AS RollingCount_PeopleVaccinated
	, SUM(CAST(death.new_deaths as bigint)) OVER (
		PARTITION BY death.location
		ORDER BY death.location
			, death.date
		) AS RollingCount_Deaths
	, SUM(CAST(death.new_cases as bigint)) OVER (
		PARTITION BY death.location
		ORDER BY death.location
			, death.date
		) AS RollingCount_Cases
FROM PortfolioProject1.dbo.CovidDeaths AS death
	INNER JOIN PortfolioProject1.dbo.CovidVaccinations AS vaccine
		ON death.location = vaccine.location
		AND death.date = vaccine.date
WHERE death.continent IS NOT NULL
