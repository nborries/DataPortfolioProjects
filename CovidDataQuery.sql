-- COVID19 DATA EXPLORATION WITH SQL --
-- NATE BORRIES, 05-09-2023 --



-- ENSURE DATA WAS IMPORTED CORRECTLY
SELECT * 
FROM CovidPortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT * 
FROM CovidPortfolioProject..CovidVaccinations
ORDER BY 3,4





-- SELECT DATA WE ARE GOING TO BE USING
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
ORDER BY 1,2





-- LOOKING USA TOTAL CASES VS TOTAL DEATHS (Death rate amongst cases), LIKELIHOOD OF DYING IF YOU CATCH COVID
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS USDeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states'
ORDER BY USDeathPercentage

-- CONTINENTS' TOTAL CASES VS TOTAL DEATHS (Death rate amongst cases), LIKELIHOOD OF DYING IF YOU CATCH COVID
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS ContDeathPerc
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD' AND location NOT LIKE '%unio%' -- filter out income and world categories, continent is null where location is the continent name.
order by ContDeathPerc DESC





-- USA TOTAL CASES VS. POPULATION, what percentage of population has been infected?
SELECT location, date, total_cases, population, (total_cases/population)*100 AS USAPercPopInfected
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states'
ORDER BY 2 DESC, USAPercPopInfected DESC -- as of today!

-- CONTINENTS' CASES VS. POPULATION, what percentage of population has been infected?
SELECT location, date, total_cases, population, (total_cases/population)*100 AS ContPercPopInfected
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD' AND location NOT LIKE '%unio%' -- filter out income and world categories, continent is null where location is the continent name.
ORDER BY 2 DESC, ContPercPopInfected DESC





-- COUNTRIES WITH HIGHEST INFECTION RATES
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercPopInfected
FROM CovidPortfolioProject..CovidDeaths
GROUP BY location, population
order by USAPercPopInfected DESC

-- CONTINENTS WITH HIGHEST INFECTION RATES
SELECT location, population, MAX(total_cases) AS ContHighestInfectionCount, MAX((total_cases/population)*100) AS ContPercPopInfected
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD'   -- filter out income and world categories, continent is null where location is the continent name.
GROUP BY location, population
ORDER BY 2 DESC, ContPercPopInfected DESC





-- COUNTRIES WITH HIGHEST DEATH RATE
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- filter out world, income categories 
GROUP BY location
order by TotalDeathCount DESC

-- CONTINENTS WITH HIGHEST DEATH COUNT
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' -- filter out income categories, continent is null where location is the continent name.
GROUP BY location
order by TotalDeathCount DESC





-- COUNTRIES WITH HIGHEST DEATH RATE
SELECT location, MAX(total_deaths/population)*100 AS CountryDeathRate
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- filter out world, income categories 
GROUP BY location
order by CountryDeathRate DESC

-- CONTINENTS WITH HIGHEST DEATH RATE (PER POPULATION)
SELECT location, MAX(total_deaths/population)*100 AS ContDeathRate
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND location NOT LIKE 'WORLD' -- filter out income and world categories, continent is null where location is the continent name.
GROUP BY location
order by ContDeathRate DESC





---- Global Death Percentage of New Cases?
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2






-- VACCINATIONS

-- WORLDWIDE VACCINATION COUNT, ROLLING COUNT INCLUDED
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount --runs only for a specific location then starts over
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3




-- want to use RollingVaccinationCount and divide by population. CTE or Temp Table needed (cant use a new column in another aggregate function)

-- USING CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationCount) --need amount of columns in CTE to match below.
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount --runs only for a specific location then starts over
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingVaccinationCount/Population)*100 -- rolling percent of populating that's vaccinated over time
FROM PopvsVac



-- ADD ANOTHER CTE FOR PROJECT


-- USING TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated -- can run multiple times without closing out table, alter name, etc.
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime, 
Population numeric, 
new_vaccinations numeric, 
RollingPeopleVaccinated numeric)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
	dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --runs only for a specific location then starts over
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 RollingPercPopVac-- rolling percent of populating that's vaccinated over time
FROM #PercentPopulationVaccinated



-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW RollingPeopleVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --runs only for a specific location then starts over
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


