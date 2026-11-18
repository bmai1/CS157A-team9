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
      <div>
      <img src="${pageContext.request.contextPath}/images/img_homepage.jpg" alt="hompage picture" style="max-width: 90%; height: auto;margin-top: 20px">
    </div>

    </div>

    <div class="match-panel">
      <div class="panel-interests">
        <p class="panel-label">Your research interests</p>
        <ul class="chips">
          <li>Machine learning</li>
          <li>Robotics</li>
          <li>Databases</li>
        </ul>
      </div>

      <div class="match-row is-best">
        <span class="tag">Best match</span>
        <p class="match-title">PhD Position in Robust Machine Learning</p>
        <p class="match-meta">Trustworthy ML Group &middot; Funded</p>
      </div>
      <div class="match-row">
        <p class="match-title">Robotics Summer Internship</p>
        <p class="match-meta">Autonomous Robotics Lab &middot; Summer 2027</p>
      </div>
      <div class="match-row">
        <p class="match-title">Undergraduate Security Research Project</p>
        <p class="match-meta">Secure Systems Lab &middot; Spring 2027</p>
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
        <p>Search by name, location, department, or research area, then see each university's departments, researchers, and open opportunities.</p>
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
        <p>Sign up as a student or researcher. Researchers add their department, lab, research areas, and PhD availability.</p>
  </li>
      <li>
        <h3>Find researchers</h3>
        <p>Search by research area, university, department, or location, and filter to researchers accepting PhD students or funded positions.</p>
  </li>
      <li>
        <h3>Reach out</h3>
        <p>Open a researcher's profile to see their publications and open positions, then email them or apply through the opportunity's link.</p>
  </li>
    </ol>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
