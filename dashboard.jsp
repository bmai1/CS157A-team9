<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  // Only logged-in users can see this page
  if (session.getAttribute("userId") == null) {
    response.sendRedirect(request.getContextPath() + "/login.jsp");
    return;
  }

  String pageTitle = "Dashboard | ResearchMatch";
  String firstName = (String) session.getAttribute("userFirstName");
  String role = (String) session.getAttribute("userRole");
  boolean isResearcher = "researcher".equalsIgnoreCase(role);
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <div class="profile-head">
      <div>
        <h1>Welcome, <%= esc(firstName) %></h1>
        <p class="sub">
          <%= isResearcher
              ? "Find collaborators and share your open positions."
              : "Find researchers and opportunities that match your interests." %>
        </p>
      </div>
    </div>

    <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:1rem;">
      <div class="card">
        <h2>Researchers</h2>
        <p>Browse researchers by research area, university, and lab.</p>
        <br>
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/researchers.jsp">Browse researchers</a>
      </div>

      <div class="card">
        <h2>Universities</h2>
        <p>Explore universities and their departments.</p>
        <br>
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/universities.jsp">Browse universities</a>
      </div>

      <div class="card">
        <h2>Opportunities</h2>
        <p>See open research positions you can apply to.</p>
        <br>
        <a class="btn btn-primary" href="${pageContext.request.contextPath}/opportunities.jsp">Browse opportunities</a>
      </div>
    </div>
  </div>
</section>