-- CREATING VIEWS FOR TABLEAU AND OTHER VISUALIZATIONS 

CREATE VIEW USACasesVsDeaths AS 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS USDeathPercentage
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states'

CREATE VIEW CONTCasesVsDeaths AS 
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS ContDeathPerc
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD' AND location NOT LIKE '%unio%' -- filter out income and world categories, continent is null where location is the continent name.

CREATE VIEW USAPercentPopulationInfected AS
SELECT location, date, total_cases, population, (total_cases/population)*100 AS USAPercPopInfected
FROM CovidPortfolioProject..CovidDeaths
WHERE location LIKE '%states'

CREATE VIEW CONTPercentPopulationInfected AS
SELECT location, date, total_cases, population, (total_cases/population)*100 AS ContPercPopInfected
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD' AND location NOT LIKE '%unio%' -- filter out income and world categories, continent is null where location is the continent name.

CREATE VIEW PercentPopInfected AS
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)*100) AS PercPopInfected
FROM CovidPortfolioProject..CovidDeaths
GROUP BY location, population

CREATE VIEW COUNTRYDeathCount AS
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- filter out world, income categories 
GROUP BY location

CREATE VIEW CONTINENTDeathCount AS
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD' AND location NOT LIKE '%unio%' -- filter out income and world categories, continent is null where location is the continent name.
GROUP BY location

CREATE VIEW COUNTRYDeathRate AS
SELECT location, MAX(total_deaths/population)*100 AS CountryDeathRate
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NOT NULL -- filter out world, income categories 
GROUP BY location

CREATE VIEW CONTDeathRate AS
SELECT location, MAX(total_deaths/population)*100 AS ContDeathRate
FROM CovidPortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income%' AND LOCATION NOT LIKE 'WORLD' AND location NOT LIKE '%unio%' -- filter out income and world categories, continent is null where location is the continent name.
GROUP BY location

CREATE VIEW RollingVaccinationCount AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinationCount --runs only for a specific location then starts over
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

CREATE VIEW RollingPeopleVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated --runs only for a specific location then starts over
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
