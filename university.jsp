<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "University | ResearchMatch";
  String error = null;

  // 1. Which university? universities.jsp links here as university.jsp?id=3
  int universityId = -1;                     // -1 matches nobody
  try {
    universityId = Integer.parseInt(request.getParameter("id"));
  } catch (NumberFormatException e) {
    // missing or not a number: keep -1, so the page says "not found"
  }

  List<Map<String, Object>> departments = new ArrayList<>();    // departments + researcher counts
  List<Map<String, Object>> researchers = new ArrayList<>();    // researchers at this university
  List<Map<String, Object>> opportunities = new ArrayList<>();  // open positions from those researchers

  Map<String, Object> uni = null;            // stays null if no university has this id

  try (Connection con = getConnection(application)) {
    // 2. The university itself
    PreparedStatement ps = con.prepareStatement(
        "SELECT name, city, state, country, website FROM university WHERE university_id = ?");
    ps.setInt(1, universityId);
    ResultSet rs = ps.executeQuery();

    if (rs.next()) {
      uni = new HashMap<>();
      uni.put("name", rs.getString("name"));
      uni.put("location", rs.getString("city") + ", " + rs.getString("state") + ", " + rs.getString("country"));
      uni.put("website", rs.getString("website"));                  // can be NULL
      pageTitle = uni.get("name") + " | ResearchMatch";

      // 3. Departments, each with how many researchers it has. LEFT JOIN keeps
      //    departments that have no researchers (an inner join would drop them).
      PreparedStatement deptPs = con.prepareStatement(
          "SELECT d.name, COUNT(r.researcher_id) AS researcher_count "
        + "FROM department d "
        + "LEFT JOIN researcher r ON r.department_id = d.department_id "
        + "WHERE d.university_id = ? "
        + "GROUP BY d.department_id, d.name "
        + "ORDER BY d.name");
      deptPs.setInt(1, universityId);
      ResultSet deptRs = deptPs.executeQuery();
      while (deptRs.next()) {
        Map<String, Object> dept = new HashMap<>();
        dept.put("name", deptRs.getString("name"));
        dept.put("count", deptRs.getInt("researcher_count"));
        departments.add(dept);
      }

      // 4. Researchers at this university (researcher -> department -> university)
      PreparedStatement resPs = con.prepareStatement(
          "SELECT r.researcher_id, u.first_name, u.last_name, r.academic_title, "
        + "       r.accepting_phd, d.name AS department_name "
        + "FROM researcher r "
        + "JOIN users u      ON u.user_id = r.researcher_id "
        + "JOIN department d ON d.department_id = r.department_id "
        + "WHERE d.university_id = ? "
        + "ORDER BY u.last_name, u.first_name");
      resPs.setInt(1, universityId);
      ResultSet resRs = resPs.executeQuery();
      while (resRs.next()) {
        Map<String, Object> r = new HashMap<>();
        r.put("id", resRs.getInt("researcher_id"));
        r.put("name", resRs.getString("first_name") + " " + resRs.getString("last_name"));
        r.put("title", resRs.getString("academic_title"));          // can be NULL
        r.put("department", resRs.getString("department_name"));
        r.put("phd", resRs.getInt("accepting_phd") == 1);
        researchers.add(r);
      }

      // 5. Open opportunities offered by those researchers
      PreparedStatement oppPs = con.prepareStatement(
          "SELECT o.opportunity_id, o.title, o.opportunity_type, o.funding_available, "
        + "       o.application_deadline, r.researcher_id, u.first_name, u.last_name "
        + "FROM opportunity o "
        + "JOIN researcher r ON r.researcher_id = o.researcher_id "
        + "JOIN users u      ON u.user_id = r.researcher_id "
        + "JOIN department d ON d.department_id = r.department_id "
        + "WHERE d.university_id = ? AND o.status = 'Open' "
        + "ORDER BY o.application_deadline IS NULL, o.application_deadline, o.title");
      oppPs.setInt(1, universityId);
      ResultSet oppRs = oppPs.executeQuery();
      while (oppRs.next()) {
        Map<String, Object> opp = new HashMap<>();
        opp.put("id", oppRs.getInt("opportunity_id"));
        opp.put("title", oppRs.getString("title"));
        opp.put("type", oppRs.getString("opportunity_type"));
        opp.put("funded", oppRs.getInt("funding_available") == 1);
        opp.put("deadline", oppRs.getString("application_deadline")); // can be NULL
        opp.put("researcherId", oppRs.getInt("researcher_id"));
        opp.put("researcher", oppRs.getString("first_name") + " " + oppRs.getString("last_name"));
        opportunities.add(opp);
      }
    }
  } catch (Exception e) {
    error = e.getMessage();
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <a class="back-link" href="universities.jsp">&larr; Back to universities</a>

    <% if (error != null) { %>
      <p class="empty">Database error: <%= esc(error) %></p>
    <% } else if (uni == null) { %>
      <p class="empty">We couldn't find that university.</p>
    <% } else {
         String website = (String) uni.get("website"); %>

      <!-- Name and location -->
      <div class="profile-head">
        <div>
          <h1><%= esc(uni.get("name")) %></h1>
          <p class="sub"><%= esc(uni.get("location")) %></p>
        </div>
      </div>

      <!-- Details -->
      <div class="card">
        <h2>About</h2>
        <dl class="facts">
          <dt>Location</dt>
          <dd><%= esc(uni.get("location")) %></dd>

          <dt>Departments</dt>
          <dd><%= departments.size() %></dd>

          <dt>Researchers</dt>
          <dd><%= researchers.size() %></dd>

          <%-- Only show the website as a link if it is a normal web address --%>
          <% if (website != null && website.startsWith("http")) { %>
            <dt>Website</dt>
            <dd><a href="<%= esc(website) %>" target="_blank"><%= esc(website) %></a></dd>
          <% } %>
        </dl>
      </div>

      <!-- Departments -->
      <div class="card">
        <h2>Departments</h2>
        <% if (departments.isEmpty()) { %>
          <p>No departments listed yet.</p>
        <% } else { %>
          <ul class="plain-list">
            <% for (Map<String, Object> dept : departments) {
                 int count = (Integer) dept.get("count"); %>
              <li>
                <p class="item-title"><%= esc(dept.get("name")) %></p>
                <p class="item-meta"><%= count %> researcher<%= count == 1 ? "" : "s" %></p>
              </li>
            <% } %>
          </ul>
        <% } %>
      </div>

      <!-- Researchers -->
      <div class="card">
        <h2>Researchers</h2>
        <% if (researchers.isEmpty()) { %>
          <p>No researchers listed yet.</p>
        <% } else { %>
          <ul class="plain-list">
            <% for (Map<String, Object> r : researchers) {
                 boolean phd = (Boolean) r.get("phd"); %>
              <li>
                <a class="item-title" href="researcher.jsp?id=<%= r.get("id") %>"><%= esc(r.get("name")) %></a>
                <p class="item-meta">
                  <%= r.get("title") == null ? "" : esc(r.get("title")) + " &middot; " %><%= esc(r.get("department")) %>
                </p>
                <span class="badge <%= phd ? "badge-yes" : "" %>">
                  <%= phd ? "Accepting PhD students" : "Not accepting PhD students" %>
                </span>
              </li>
            <% } %>
          </ul>
        <% } %>
      </div>

      <!-- Open opportunities -->
      <div class="card">
        <h2>Open opportunities</h2>
        <% if (opportunities.isEmpty()) { %>
          <p>No open opportunities right now.</p>
        <% } else { %>
          <ul class="plain-list">
            <% for (Map<String, Object> opp : opportunities) {
                 boolean funded = (Boolean) opp.get("funded"); %>
              <li>
                <a class="item-title" href="opportunity.jsp?id=<%= opp.get("id") %>"><%= esc(opp.get("title")) %></a>
                <p class="item-meta">
                  <%= esc(opp.get("type")) %>
                  <%= opp.get("deadline") == null ? "" : " &middot; Apply by " + esc(opp.get("deadline")) %>
                  &middot; <a href="researcher.jsp?id=<%= opp.get("researcherId") %>"><%= esc(opp.get("researcher")) %></a>
                </p>
                <span class="badge <%= funded ? "badge-yes" : "" %>"><%= funded ? "Funded" : "Unfunded" %></span>
              </li>
            <% } %>
          </ul>
        <% } %>
      </div>
    <% } %>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
