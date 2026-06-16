class ProjectsController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    @projects = Project.by_year
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to projects_url, notice: "Project was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    if @project.update(project_params)
      redirect_to projects_url, notice: "Project was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy
    redirect_to projects_url, notice: "Project was successfully destroyed."
  end

  private

  def project_params
    params.expect(project: [ :name, :year, :github_url, :license, :language, :description ])
  end
end
