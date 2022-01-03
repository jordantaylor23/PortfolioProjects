/*
Covid 19 Data Exploration
Data from https://ourworldindata.org/covid-deaths
Guidance by Alex The Analyst on YouTube

Skills used: Joins, CTEs, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


-- Given how the dataset is setup, filtering the data to where continent is not null gets rid of 'locations' that are actually entire continents in the data

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4


-- Select data to start with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in your country
-- In the calculation, I converted total_deaths and total_cases to avoid getting an error with NULL data

SELECT location, date, total_cases, total_deaths, (CONVERT(float,total_deaths)/CONVERT(float,total_cases)*100) as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentageOfPopulationInfected
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2


-- Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentageOfPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentageOfPopulationInfected DESC


-- Countries with highest death count per population

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount -- total_deaths was nvarchar, so I casted it as int
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing continents with the highest death count per population

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount --total_deaths was nvarchar, so I casted it
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL -- Ironically, this code is how this dataset can be brought up to the continent level
GROUP BY location
ORDER BY TotalDeathCount DESC



-- GLOBAL NUMBERS

-- Total Cases vs Total Deaths on a day-by-day basis
-- Shows the likelihood of dying if you contract COVID

SELECT date, SUM(cast(new_cases as int)) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- United States' rolling number of vaccinations over time
-- Shows percentage of population that has received at least one Covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
AND dea.location = 'United States'
order by 2,3


-- Using a CTE to perform calculation on Parition By in previous query
-- Looks at United States' population, new vaccinations each day, a rolling count of people vaccinated, and the percentage of the population that is therefore vaccinated up to that date

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
	(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	AND dea.location = 'United States'
	)
SELECT *, (RollingPeopleVaccinated/population)*100 as RollingPercentOfPopulationVaccinated
FROM PopvsVac


-- Using a Temp Table to perform calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated -- this line of code allows me to make changes to the code below, and re-run the code without errors
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null
	AND dea.location = 'United States'

SELECT *, (RollingPeopleVaccinated/population)*100 as RollingPercentOfPopulationVaccinated
FROM #PercentPopulationVaccinated


-- Creating View to store data for Tableau visualizations

Create View PercentPopulationVaccinated as
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		and dea.date = vac.date
	WHERE dea.continent is not null


SELECT * FROM PercentPopulationVaccinated