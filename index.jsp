<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String pageTitle = "ResearchMatch"; %>
<%@ include file="includes/header.jspf" %>

<section class="hero">
  <div class="container">
    <div>
      <h1>Find the research that fits you.</h1>
      <p class="lead">
        ResearchMatch helps students quickly discover research opportunities and stuff
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
          <li>Afghjkl</li>
        </ul>
      </div>

      <div class="match-row is-best">
        <span class="tag">Best match</span>
        <p class="match-title">Predicting flu outbreaks from clinic data</p>
        <p class="match-meta">Public Health Lab &middot; 6 hours a week</p>
      </div>
      <div class="match-row">
        <p class="match-title">Sleep and memory study</p>
        <p class="match-meta">Psychology Lab &middot; 4 hours a week</p>
      </div>
      <div class="match-row">
        <p class="match-title">Low-cost air quality sensors</p>
        <p class="match-meta">Environmental Engineering &middot; 8 hours a week</p>
      </div>

      <p class="panel-caption">Sample matches</p>
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
        <p>text text text text</p>
      </li>
      <li>
        <h3>Reach out</h3>
        <p>text text text</p>
      </li>
    </ol>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
