<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Opportunity | ResearchMatch";
  String error = null;

  // 1. Which opportunity? opportunities.jsp links here as opportunity.jsp?id=5
  int opportunityId = -1;                    // -1 matches nobody
  try {
    opportunityId = Integer.parseInt(request.getParameter("id"));
  } catch (NumberFormatException e) {
    // missing or not a number: keep -1, so the page says "not found"
  }

  List<String> areas = new ArrayList<>();                        // research areas of the researcher
  List<Map<String, Object>> others = new ArrayList<>();          // the researcher's other open positions

  Map<String, Object> opp = null;            // stays null if no opportunity has this id

  // Saving: only for logged-in students
  boolean isStudent = "student".equals(session.getAttribute("userRole"));
  int userId = isStudent ? (Integer) session.getAttribute("userId") : -1;
  boolean hasStudentRow = false;             // true once the student has saved their major
  boolean isSaved = false;                   // true if this student already saved this opportunity

  try (Connection con = getConnection(application)) {
	    // 1b. Save or unsave, if a student clicked the button. The form sends
	    //     action=save or action=unsave and the opportunity id.
	    if ("POST".equalsIgnoreCase(request.getMethod()) && isStudent) {
	      String action = request.getParameter("action");
	      if ("save".equals(action)) {
	        // Only save if it isn't saved already: (student_id, opportunity_id) is the
	        // primary key, so saving the same opportunity twice would be an error.
	        PreparedStatement checkPs = con.prepareStatement(
	            "SELECT student_id FROM saved_opportunity WHERE student_id = ? AND opportunity_id = ?");
	        checkPs.setInt(1, userId);
	        checkPs.setInt(2, opportunityId);
	        if (!checkPs.executeQuery().next()) {
	          // saved_at fills itself in (DEFAULT CURRENT_TIMESTAMP); notes start empty (NULL)
	          PreparedStatement savePs = con.prepareStatement(
	              "INSERT INTO saved_opportunity (student_id, opportunity_id) VALUES (?, ?)");
	          savePs.setInt(1, userId);
	          savePs.setInt(2, opportunityId);
	          savePs.executeUpdate();
	        }
	      } else if ("unsave".equals(action)) {
	        PreparedStatement unsavePs = con.prepareStatement(
	            "DELETE FROM saved_opportunity WHERE student_id = ? AND opportunity_id = ?");
	        unsavePs.setInt(1, userId);
	        unsavePs.setInt(2, opportunityId);
	        unsavePs.executeUpdate();
	      }
	      response.sendRedirect(request.getContextPath() + "/opportunity.jsp?id=" + opportunityId);
	      return;
	    }
    // 2. The opportunity plus who offers it and where (theta joins on the foreign keys)
    PreparedStatement ps = con.prepareStatement(
        "SELECT o.title, o.description, o.opportunity_type, o.funding_available, "
      + "       o.expected_start_term, o.application_deadline, o.status, o.application_url, "
      + "       r.researcher_id, r.academic_title, u.first_name, u.last_name, "
      + "       d.name AS department_name, un.university_id, un.name AS university_name "
      + "FROM opportunity o "
      + "JOIN researcher r  ON r.researcher_id = o.researcher_id "
      + "JOIN users u       ON u.user_id = r.researcher_id "
      + "JOIN department d  ON d.department_id = r.department_id "
      + "JOIN university un ON un.university_id = d.university_id "
      + "WHERE o.opportunity_id = ?");
    ps.setInt(1, opportunityId);
    ResultSet rs = ps.executeQuery();

    if (rs.next()) {
      opp = new HashMap<>();
      opp.put("title", rs.getString("title"));
      opp.put("description", rs.getString("description"));            // can be NULL
      opp.put("type", rs.getString("opportunity_type"));
      opp.put("funded", rs.getInt("funding_available") == 1);
      opp.put("start", rs.getString("expected_start_term"));          // can be NULL
      opp.put("deadline", rs.getString("application_deadline"));      // can be NULL
      opp.put("status", rs.getString("status"));
      opp.put("url", rs.getString("application_url"));                // can be NULL
      opp.put("researcherId", rs.getInt("researcher_id"));
      opp.put("researcherTitle", rs.getString("academic_title"));     // can be NULL
      opp.put("researcher", rs.getString("first_name") + " " + rs.getString("last_name"));
      opp.put("department", rs.getString("department_name"));
      opp.put("universityId", rs.getInt("university_id"));
      opp.put("university", rs.getString("university_name"));
      pageTitle = opp.get("title") + " | ResearchMatch";

      int researcherId = (Integer) opp.get("researcherId");

      // 3. The researcher's research areas, to help a student judge the fit
      PreparedStatement areaPs = con.prepareStatement(
          "SELECT ra.name "
        + "FROM researcher_research_area rra "
        + "JOIN research_area ra ON ra.area_id = rra.area_id "
        + "WHERE rra.researcher_id = ? "
        + "ORDER BY ra.name");
      areaPs.setInt(1, researcherId);
      ResultSet areaRs = areaPs.executeQuery();
      while (areaRs.next()) {
        areas.add(areaRs.getString("name"));
      }

      // 4. The same researcher's other open positions (not this one)
      PreparedStatement otherPs = con.prepareStatement(
          "SELECT opportunity_id, title, opportunity_type, application_deadline "
        + "FROM opportunity "
        + "WHERE researcher_id = ? AND status = 'Open' AND opportunity_id <> ? "
        + "ORDER BY application_deadline IS NULL, application_deadline, title");
      otherPs.setInt(1, researcherId);
      otherPs.setInt(2, opportunityId);
      ResultSet otherRs = otherPs.executeQuery();
      while (otherRs.next()) {
        Map<String, Object> o = new HashMap<>();
        o.put("id", otherRs.getInt("opportunity_id"));
        o.put("title", otherRs.getString("title"));
        o.put("type", otherRs.getString("opportunity_type"));
        o.put("deadline", otherRs.getString("application_deadline"));
        others.add(o);
      }
    }

    // 5. For students: do they have a student row yet and did they save this one?
    if (isStudent) {
      PreparedStatement stuPs = con.prepareStatement("SELECT student_id FROM student WHERE student_id = ?");
      stuPs.setInt(1, userId);
      hasStudentRow = stuPs.executeQuery().next();

      PreparedStatement savedPs = con.prepareStatement(
          "SELECT saved_at FROM saved_opportunity WHERE student_id = ? AND opportunity_id = ?");
      savedPs.setInt(1, userId);
      savedPs.setInt(2, opportunityId);
      isSaved = savedPs.executeQuery().next();
    }
  } catch (Exception e) {
    error = e.getMessage();
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <a class="back-link" href="opportunities.jsp">&larr; Back to opportunities</a>

    <% if (error != null) { %>
      <p class="empty">Database error: <%= esc(error) %></p>
    <% } else if (opp == null) { %>
      <p class="empty">We couldn't find that opportunity.</p>
    <% } else {
         boolean funded = (Boolean) opp.get("funded");
         boolean isOpen = "Open".equalsIgnoreCase((String) opp.get("status"));
         String url = (String) opp.get("url"); %>

      <!-- Title, type, and funding -->
      <div class="profile-head">
        <div>
          <h1><%= esc(opp.get("title")) %></h1>
          <p class="sub"><%= esc(opp.get("type")) %></p>
        </div>
        <span class="badge <%= funded ? "badge-yes" : "" %>"><%= funded ? "Funded" : "Unfunded" %></span>
      </div>

      <!-- Details -->
      <div class="card">
        <h2>Details</h2>
        <dl class="facts">
          <dt>Offered by</dt>
          <dd>
            <a href="researcher.jsp?id=<%= opp.get("researcherId") %>"><%= esc(opp.get("researcher")) %></a>
            <%= opp.get("researcherTitle") == null ? "" : " (" + esc(opp.get("researcherTitle")) + ")" %>
          </dd>

          <dt>Department</dt>
          <dd><%= esc(opp.get("department")) %></dd>

          <dt>University</dt>
          <dd><a href="university.jsp?id=<%= opp.get("universityId") %>"><%= esc(opp.get("university")) %></a></dd>

          <dt>Research areas</dt>
          <dd>
            <% if (areas.isEmpty()) { %>
              None listed
            <% } else { %>
              <ul class="chips">
                <% for (String areaName : areas) { %>
                  <li><%= esc(areaName) %></li>
                <% } %>
              </ul>
            <% } %>
          </dd>

          <dt>Expected start</dt>
          <dd><%= opp.get("start") == null ? "Not specified" : esc(opp.get("start")) %></dd>

          <dt>Application deadline</dt>
          <dd><%= opp.get("deadline") == null ? "Not specified" : esc(opp.get("deadline")) %></dd>

          <dt>Status</dt>
          <dd><%= esc(opp.get("status")) %></dd>
        </dl>

        <% if (opp.get("description") != null) { %>
          <h2 class="card-subhead">Description</h2>
          <p style="white-space: pre-line;"><%= esc(opp.get("description")) %></p>
        <% } %>

        <%-- Only offer the Apply link for open positions with a normal web address --%>
        <% if (isOpen && url != null && url.startsWith("http")) { %>
          <p><a class="btn btn-primary" href="<%= esc(url) %>" target="_blank">Apply &rarr;</a></p>
        <% } else if (!isOpen) { %>
          <p>This position is no longer open.</p>
        <% } %>
        <%-- Save button: students only. A student needs a student row (their major) first,
             because saved_opportunity has a foreign key to student. --%>
        <% if (isStudent && !hasStudentRow) { %>
          <p class="hint"><a href="profile.jsp">Add your major on My profile</a> to save opportunities.</p>
        <% } else if (isStudent) { %>
          <form action="opportunity.jsp?id=<%= opportunityId %>" method="post" class="save-form">
            <input type="hidden" name="id" value="<%= opportunityId %>">
            <input type="hidden" name="action" value="<%= isSaved ? "unsave" : "save" %>">
            <button type="submit" class="btn btn-secondary"><%= isSaved ? "&#9733; Saved (click to remove)" : "&#9734; Save opportunity" %></button>
          </form>
        <% } else if (session.getAttribute("userId") == null) { %>
          <p class="hint"><a href="login.jsp">Log in as a student</a> to save this opportunity.</p>
        <% } %>
      </div>

      <!-- Other positions from the same researcher -->
      <div class="card">
        <h2>More from <%= esc(opp.get("researcher")) %></h2>
        <% if (others.isEmpty()) { %>
          <p>No other open opportunities from this researcher.</p>
        <% } else { %>
          <ul class="plain-list">
            <% for (Map<String, Object> o : others) { %>
              <li>
                <a class="item-title" href="opportunity.jsp?id=<%= o.get("id") %>"><%= esc(o.get("title")) %></a>
                <p class="item-meta">
                  <%= esc(o.get("type")) %>
                  <%= o.get("deadline") == null ? "" : " &middot; Apply by " + esc(o.get("deadline")) %>
                </p>
              </li>
            <% } %>
          </ul>
        <% } %>
      </div>
    <% } %>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
