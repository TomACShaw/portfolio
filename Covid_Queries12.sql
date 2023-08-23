
--Select all data from each table
Select *
From PortfolioProject..CovidDeaths
where continent is not null
--and location = 'Luxembourg'
order by 3,4;

Select *
From PortfolioProject..CovidVaccinations
order by 3,4;


--Select the data we will be using
Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2;


--Total Cases vs. Population
--Shows infection rate of total population
Select location, date, population, total_cases, (total_cases/population)*100 as infection_rate
From PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2;


--Total Cases vs. Total Deaths
--Shows mortality rate of infected population in the United States
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
and location like '%states%'
order by 1,2;


--Showing countries with highest infection rate compared to overall population
Select location, population, MAX(total_cases/population)*100 as max_infection_rate
From PortfolioProject..CovidDeaths
where continent is not null
and date = '2021-04-30 00:00:00.000'
group by location, population
order by 3 desc;


--Showing countries with highest mortality rate of infected population
Select location, population,
	MAX((cast(total_deaths as int)/total_cases)*100) as infected_mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
and date = '2021-04-30 00:00:00.000'
group by location, population
order by infected_mortality_rate desc;


--Showing countries with highest mortality rate compared to overall population
Select location, population, MAX(cast(total_deaths as int)) as max_deaths,
	MAX((cast(total_deaths as int)/population)*100) as population_mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
and date = '2021-04-30 00:00:00.000'
group by location, population
order by population_mortality_rate desc;



--COMPARING DATA BY CONTINENT


--Showing continents with highest infection rate compared to overall population
Select location, population, MAX(total_cases) as max_cases,
	MAX((total_cases/population)*100) as population_infection_rate
From PortfolioProject..CovidDeaths
where continent is null
and date = '2021-04-30 00:00:00.000'
group by location, population
order by population_infection_rate desc;


--Showing continents with highest mortality rate compared to overall population
Select location, population, MAX(cast(total_deaths as int)) as max_deaths,
	MAX((cast(total_deaths as int)/population)*100) as population_mortality_rate
From PortfolioProject..CovidDeaths
where continent is null
and date = '2021-04-30 00:00:00.000'
group by location, population
order by population_mortality_rate desc;



--Showing continents with highest mortality rate compared to population, the hard way
WITH max_deaths_per_country AS (
Select continent, MAX(population) as population, location, MAX(cast(total_deaths as int)) as max_deaths,
	MAX((cast(total_deaths as int)/population)*100) as population_mortality_rate
From PortfolioProject..CovidDeaths dea
where continent is not null
and date = '2021-04-30 00:00:00.000'
group by continent, location
)
Select continent,
	   SUM(max_deaths) as total_continental_deaths,
	   SUM(population) as continental_population,
	   (SUM(max_deaths)/SUM(population)*100) as continental_mortality_rate
From max_deaths_per_country mdcp
group by continent
order by continent;


--Alex's query for breaking down by continent
Select continent, MAX(cast(total_deaths as int)) as max_deaths
From PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by max_deaths desc;


--GLOBAL NUMBERS

Select date,
	   SUM(population) as global_population,
	   SUM(total_cases) as total_global_cases,
	   SUM(CONVERT(int, total_deaths)) as total_global_deaths,
	   SUM(total_cases)/SUM(population)*100 as global_infection_rate,
	   SUM(CONVERT(int, total_deaths))/SUM(total_cases)*100 as global_infected_mortality_rate,
	   SUM(CONVERT(int, total_deaths))/SUM(population)*100 as global_population_mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
--and date = '2021-04-30 00:00:00.000'
and new_cases <> 0
and new_deaths <> 0
Group By date
order by date



-- DEATHS AND VACCINATIONS


--Showing global rolling vaccination rate
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by
	   dea.location, dea.date) as rolling_total_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3;


-- Using a CTE to show rolling vaccination rate per country
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Total_Vaccinations) as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by
	   dea.location, dea.date) as rolling_total_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and dea.location = 'Gibraltar'
)
Select *, (Rolling_Total_Vaccinations/Population)*100 as rolling_vaccination_rate
From PopVsVac
order by 2,3;


--Using a CTE to show countries with the highest vaccination rate
--The data are incorrect - the maximum vaccination rate for Gibraltar is given as 182.17%, which is impossible
With PopVsVac (/*Continent,*/ Location/*, Date*/, Population, New_Vaccinations, Rolling_Total_Vaccinations) as (
Select /*dea.continent,*/ dea.location/*, dea.date*/, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by
	   dea.location/*, dea.date*/) as rolling_total_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select location, population, MAX(Rolling_Total_Vaccinations) as max_vaccinations, MAX((Rolling_Total_Vaccinations/Population)*100) as max_vaccination_rate
From PopVsVac
group by location, population
order by max_vaccination_rate desc;


--Using a Temp Table
Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	new_vaccinations numeric,
	rolling_total_vaccinations numeric
)
Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by
	   dea.location, dea.date) as rolling_total_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select *, (Rolling_Total_Vaccinations/Population)*100 as rolling_vaccination_rate
From #PercentPopulationVaccinated
order by 2,3;


--CREATING VIEWS FOR LATER VISUALIZATION

--View showing global rolling vaccination rate
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by
	   dea.location, dea.date) as rolling_total_vaccinations
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


--Total Cases vs. Population
--Create a view showing infection rate of total population
Create View InfectionRate as
Select location, date, population, total_cases, (total_cases/population)*100 as infection_rate
From PortfolioProject..CovidDeaths
where continent is not null
--order by 1, 2;


--Total Cases vs. Total Deaths
--Create a view showing mortality rate of infected population
Create View InfectedMortalityRate as
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
--and location like '%states%'
--order by 1,2;


--Create a view showing countries with highest infection rate compared to overall population
Create View InfectionRateByCountry as
Select location, population, MAX(total_cases/population)*100 as max_infection_rate
From PortfolioProject..CovidDeaths
where continent is not null
group by location, population
--order by 3 desc;


--Create a view showing countries with highest mortality rate of infected population
Create View InfectedMortalityRateByCountry as
Select location, population, total_deaths,
	(cast(total_deaths as int)/total_cases)*100 as infected_mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
	and date = '2021-04-30 00:00:00.000'
--group by location, population, total_deaths
--order by infected_mortality_rate desc;


--Create a view showing countries with highest mortality rate compared to overall population
Create View PopulationMortalityRateByCountry as
Select location, population, MAX(cast(total_deaths as int)) as max_deaths,
	MAX((cast(total_deaths as int)/population)*100) as population_mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
group by location, population
--order by population_mortality_rate desc;


--Create a view showing global infection and mortality rates
Create View GlobalRates as
Select date,
	   SUM(population) as global_population,
	   SUM(total_cases) as total_global_cases,
	   SUM(CONVERT(int, total_deaths)) as total_global_deaths,
	   SUM(total_cases)/SUM(population)*100 as global_infection_rate,
	   SUM(CONVERT(int, total_deaths))/SUM(total_cases)*100 as global_infected_mortality_rate,
	   SUM(CONVERT(int, total_deaths))/SUM(population)*100 as global_population_mortality_rate
From PortfolioProject..CovidDeaths
where continent is not null
--and date = '2020-02-02 00:00:00.000'
and new_cases <> 0
and new_deaths <> 0
Group By date
order by date