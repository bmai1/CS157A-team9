<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String pageTitle = "ResearchMatch"; %>
<%@ include file="includes/header.jspf" %>

<section class="hero">
  <div class="container">
    <div>
      <h1><b>Find the research that fits you.</b></h1>
      <p class="lead">
        ResearchMatch helps students quickly discover research opportunities.
      </p>
      <div class="hero-actions">
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/register.jsp">Create account</a>
        <a class="btn btn-secondary" href="${pageContext.request.contextPath}/login.jsp">Log in</a>
      </div>
    </div>

    <div class="match-panel">
      <div class="panel-interests">
        <p class="panel-label">Your research interests</p>
        <ul class="chips">
          <li>Machine learning</li>
          <li>Robotics</li>
          <li>Money</li>
        </ul>
      </div>

      <div class="match-row is-best">
        <span class="tag">Best match</span>
        <p class="match-title">Cancer research</p>
        <p class="match-meta">Public Health Lab &middot; Full-time</p>
      </div>
      <div class="match-row">
        <p class="match-title">Sleep deprivation study</p>
        <p class="match-meta">Psychology Lab &middot; Part-time</p>
      </div>
      <div class="match-row">
        <p class="match-title">Save Earth before it explodes!!!</p>
        <p class="match-meta">Environmental Engineering &middot; 8 hours a week</p>
      </div>

      <p class="panel-caption">Sample matches</p>
    </div>
  </div>
</section>
<!-- Start exploring: one card for each search page -->
<section class="explore">
  <div class="container">
    <h2>Start exploring</h2>
    <p class="sub">No account needed to search.</p>

    <div class="explore-grid">
      <a class="explore-card" href="${pageContext.request.contextPath}/researchers.jsp">
        <h3>Researchers</h3>
        <p>Search by name, research area, university, department, or location, and see who is accepting PhD students.</p>
        <span class="explore-link">Find researchers &rarr;</span>
      </a>
      <a class="explore-card" href="${pageContext.request.contextPath}/universities.jsp">
        <h3>Universities</h3>
        <p>Search by name, location, department, or research area, then see each university's departments, labs, and researchers.</p>
        <span class="explore-link">Find universities &rarr;</span>
      </a>
      <a class="explore-card" href="${pageContext.request.contextPath}/opportunities.jsp">
        <h3>Opportunities</h3>
        <p>Browse open positions by keyword, type, research area, and university, and filter to funded ones.</p>
        <span class="explore-link">Find opportunities &rarr;</span>
      </a>
    </div>
  </div>
</section>
<section class="how">
  <div class="container">
    <h2>How it works</h2>
    <ol class="steps-list">
      <li>
        <h3>Create your profile</h3>
        <p>Add your research interests.</p>
      </li>
      <li>
        <h3>Find researchers</h3>
        <p>text text text</p>
      </li>
      <li>
        <h3>Reach out</h3>
        <p>text text text</p>
      </li>
    </ol>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
