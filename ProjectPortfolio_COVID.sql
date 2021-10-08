USE PortfolioProject
GO

--===============================================
--TOTAL CASES VS DEATH CASES
--===============================================
SELECT location,date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM WRK_CovidDeaths

--===============================================
--TOTAL CASES VS POPULATION
--% of population got COVID
--===============================================
SELECT location, (total_cases/NULLIF(population, 0))*100 as DeathByPopulation
FROM WRK_CovidDeaths

--===============================================
-- Showing CONTINENT(wise) with highest death counts (per population)
--===============================================
SELECT continent, MAX(total_deaths) as Cnt_TotalDeaths
FROM WRK_CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Cnt_TotalDeaths desc
--(6 rows affected)

--===============================================
--GLOBAL COUNTS(BY DATE)
--===============================================
SELECT date, SUM(new_cases) AS NEW_CASES, SUM(new_deaths) AS NEW_DEATHS,
SUM(NULLIF(new_deaths, 0))/SUM(NULLIF(new_cases,0))*100 as DeathPercentage
FROM WRK_CovidDeaths
WHERE continent IS NOT NULL
GROUP BY DATE
ORDER BY 1, 2
--(644 rows affected)

--===============================================
--GLOBAL COUNTS - COMPLETE
--===============================================
SELECT SUM(new_cases) AS TOT_NEW_CASES, SUM(new_deaths) AS TOT_NEW_DEATHS,
SUM(NULLIF(new_deaths, 0))/SUM(NULLIF(new_cases,0))*100 as TOT_DEATH_PER
FROM WRK_CovidDeaths
--(1 row affected)


--=============================================================
--CALCULATION - VACCINATION BY POPULATION(Based on location)
--=============================================================

--=============================================================
-- BREAK 1
-- PERFORMING JOINS ON COVIDDEATHS AND COVIDVACCINATIONDETAILS
--=============================================================
SELECT *
FROM WRK_CovidDeaths AS D
JOIN WRK_CovidVaccinationDetails AS V
ON D.location = V.location 
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--(121539 rows affected)

--===================================================================
-- BREAK 2
-- CALCULATION - TOTALPOULATION VS VACCINATIONDETAILS (ROLLING COUNT)
-- USING LOCATION TO PARTITION AND LOCATION,DATE TO ORDER
--===================================================================
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(V.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS ROLLINGCOUNT
FROM WRK_CovidDeaths AS D
JOIN WRK_CovidVaccinationDetails AS V
ON D.location = V.location 
	AND D.date = V.date
WHERE D.continent IS NOT NULL
--(116006 rows affected)


--===================================================================
-- CALCULATION - VACCINATION BY POPULATION(Based on location)
-- USING CTE
--===================================================================
WITH VACBYPOP (continent, location, date, population, new_vaccinations, rollingcount)
as
(
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(V.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS ROLLINGCOUNT
FROM WRK_CovidDeaths AS D
JOIN WRK_CovidVaccinationDetails AS V
ON D.location = V.location 
	AND D.date = V.date
WHERE D.continent IS NOT NULL
)
SELECT * , (NULLIF(rollingcount,0)/NULLIF(population,0))*100 AS PER_VACbyPOP
FROM VACBYPOP
--(116006 rows affected)


--CREATING VIEW TO STORE DATE FOR VISUALIZATIONS
CREATE VIEW PopulationVaccinatedPercent as
SELECT D.continent, D.location, D.date, D.population, V.new_vaccinations,
SUM(V.new_vaccinations) OVER (PARTITION BY D.location ORDER BY D.location, D.date) AS ROLLINGCOUNT
FROM WRK_CovidDeaths AS D
JOIN WRK_CovidVaccinationDetails AS V
ON D.location = V.location 
	AND D.date = V.date
WHERE D.continent IS NOT NULL


SELECT * 
FROM PopulationVaccinatedPercent