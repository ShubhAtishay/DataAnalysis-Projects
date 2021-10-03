USE PortfolioProjects

select * from dbo.CovidDeaths order by 3,4

--select * from dbo.CovidVaccinations order by 3,4

select location, date, total_cases, new_cases, total_deaths, population 
from dbo.CovidDeaths
order by 1,2

--Total cases vs Total deaths

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS [Death%]
from dbo.CovidDeaths
where location = 'India'
order by 1,2

--Total cases vs Population

select location, date, total_cases, population, (total_cases/population)*100 AS [Infection%]
from dbo.CovidDeaths
where location = 'India'
order by 1,2

--Countries with highest infection rate wrt population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 AS [Infection%]
from dbo.CovidDeaths
where continent is not null
group by location, population
order by [Infection%] DESC

--Countries with highest death count

select location, max(cast(total_deaths as int)) as DeathCount
from dbo.CovidDeaths
where continent is not null
group by location
order by DeathCount DESC

--Continents with highest death count

select continent, max(cast(total_deaths as int)) as DeathCount
from dbo.CovidDeaths
where continent is not null
group by continent
order by DeathCount DESC

select location, max(cast(total_deaths as int)) as DeathCount
from dbo.CovidDeaths
where continent is null
group by location
order by DeathCount DESC

--Global aggregates

select date, sum(new_cases) total_cases, sum(cast(new_deaths as int)) total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 DeathPercentage
from dbo.CovidDeaths
where continent is not null
group by date
order by date

--Rolling global sum

select continent, location, date, new_vaccinations, 
sum(convert(int, new_vaccinations)) OVER (Partition by location order by location, date) AS RollingSum
from dbo.CovidVaccinations
where continent is not null
order by 2,3

--Total population vs vaccination

select Vac.continent, Vac.location, Vac.date, new_vaccinations, dea.population,
sum(convert(int, new_vaccinations)) OVER (Partition by vac.location order by vac.location, vac.date) AS RollingSum
from dbo.CovidVaccinations Vac
JOIN dbo.CovidDeaths Dea
on vac.location=dea.location and vac.date=dea.date
where vac.continent is not null
order by 2,3

--Using CTE to perform calculations

With VaccPercentage
AS
(select Vac.continent, Vac.location, Vac.date, new_vaccinations, dea.population,
sum(convert(int, new_vaccinations)) OVER (Partition by vac.location order by vac.location, vac.date) AS RollingSum
from dbo.CovidVaccinations Vac
JOIN dbo.CovidDeaths Dea
on vac.location=dea.location and vac.date=dea.date
where vac.continent is not null
--order by 2,3
)
select *, (RollingSum/Population)*100 AS Percentage from VaccPercentage order by location, date

--Using TEMP table to perform calculations

DROP table IF Exists #VaccPercentage
Create table #VaccPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
new_vaccinations numeric,
population numeric,
rollingsum numeric
) 
Insert into #VaccPercentage
select Vac.continent, Vac.location, Vac.date, new_vaccinations, dea.population,
sum(convert(int, new_vaccinations)) OVER (Partition by vac.location order by vac.location, vac.date) AS RollingSum
from dbo.CovidVaccinations Vac
JOIN dbo.CovidDeaths Dea
on vac.location=dea.location and vac.date=dea.date
where vac.continent is not null

select *, (RollingSum/Population)*100 AS Percentage from #VaccPercentage order by location,date

--Using VIEWS to implement and store calculations and logic for future visualization purpose
GO
CREATE view VaccinationPercentage
as
select Vac.continent, Vac.location, Vac.date, new_vaccinations, dea.population,
sum(convert(int, new_vaccinations)) OVER (Partition by vac.location order by vac.location, vac.date) AS RollingSum
from dbo.CovidVaccinations Vac
JOIN dbo.CovidDeaths Dea
on vac.location=dea.location and vac.date=dea.date
where vac.continent is not null
GO
select * from dbo.VaccinationPercentage

--Using Store Proc to perform calculations

USE PortfolioProjects;
GO
CREATE Procedure dbo.uspVaccinationPercentage
	@Tablename1 nvarchar(50),
	@Tablename2 nvarchar(50)
AS
BEGIN
Declare @Query nvarchar(max)
SET @Query = 'select Vac.continent, Vac.location, Vac.date, new_vaccinations, dea.population,
sum(convert(int, new_vaccinations)) OVER (Partition by vac.location order by vac.location, vac.date) AS RollingSum
from '+ @Tablename1 + ' Vac
JOIN ' + @Tablename2 + ' Dea
on vac.location=dea.location and vac.date=dea.date
where vac.continent is not null
order by vac.location,vac.date;'
EXEC sp_executesql @Query
END
GO
EXEC dbo.uspVaccinationPercentage @Tablename1= 'dbo.CovidVaccinations', @Tablename2 ='dbo.CovidDeaths'