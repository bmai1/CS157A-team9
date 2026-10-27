<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Find opportunities | ResearchMatch";
  String error = null;

  // 1. Read the search form (null the first time the page opens)
  String keyword = request.getParameter("q");
  String type = request.getParameter("type");                  // drop down: an opportunity_type, or "" for any
  String areaId = request.getParameter("area");                // drop down: an area_id, or "" for any
  String universityId = request.getParameter("university");    // drop down: a university_id, or "" for any
  boolean fundedOnly = "1".equals(request.getParameter("funded"));

  if (keyword == null) keyword = "";
  if (type == null) type = "";
  if (areaId == null) areaId = "";
  if (universityId == null) universityId = "";
  keyword = keyword.trim();

  List<Map<String, Object>> opportunities = new ArrayList<>();
  List<String> types = new ArrayList<>();                        // choices for the Type drop-down
  List<Map<String, Object>> areas = new ArrayList<>();           // choices for the Research area drop-down
  List<Map<String, Object>> universities = new ArrayList<>();    // choices for the University drop-down

  try (Connection con = getConnection(application)) {
    // 0. Fill the drop-downs from the database
    Statement typeStmt = con.createStatement();
    ResultSet typeRs = typeStmt.executeQuery(
        "SELECT DISTINCT opportunity_type FROM opportunity WHERE opportunity_type IS NOT NULL ORDER BY opportunity_type");
    while (typeRs.next()) {
      types.add(typeRs.getString("opportunity_type"));
    }

    Statement areaStmt = con.createStatement();
    ResultSet areaRs = areaStmt.executeQuery("SELECT area_id, name FROM research_area ORDER BY name");
    while (areaRs.next()) {
      Map<String, Object> a = new HashMap<>();
      a.put("id", String.valueOf(areaRs.getInt("area_id")));
      a.put("name", areaRs.getString("name"));
      areas.add(a);
    }

    Statement uniStmt = con.createStatement();
    ResultSet uniRs = uniStmt.executeQuery("SELECT university_id, name FROM university ORDER BY name");
    while (uniRs.next()) {
      Map<String, Object> un = new HashMap<>();
      un.put("id", String.valueOf(uniRs.getInt("university_id")));
      un.put("name", uniRs.getString("name"));
      universities.add(un);
    }

    // 2. Build the query. Only open positions are listed, since those are the
    //    ones a student can still apply to. Each filter adds an "AND ...".
    StringBuilder sql = new StringBuilder(
        "SELECT o.opportunity_id, o.title, o.description, o.opportunity_type, o.funding_available, "
      + "       o.expected_start_term, o.application_deadline, "
      + "       r.researcher_id, u.first_name, u.last_name, "
      + "       d.name AS department_name, un.name AS university_name "
      + "FROM opportunity o "
      + "JOIN researcher r  ON r.researcher_id = o.researcher_id "
      + "JOIN users u       ON u.user_id = r.researcher_id "
      + "JOIN department d  ON d.department_id = r.department_id "
      + "JOIN university un ON un.university_id = d.university_id "
      + "WHERE o.status = 'Open' ");

    List<Object> params = new ArrayList<>();

    if (!keyword.isEmpty()) {
      sql.append("AND (o.title LIKE ? OR o.description LIKE ?) ");
      params.add("%" + keyword + "%");
      params.add("%" + keyword + "%");
    }
    if (!type.isEmpty()) {
      sql.append("AND o.opportunity_type = ? ");
      params.add(type);
    }
    if (!universityId.isEmpty()) {
      sql.append("AND un.university_id = ? ");
      params.add(Integer.parseInt(universityId));
    }
    if (!areaId.isEmpty()) {
      // An opportunity has no research area of its own, so we use the areas of the
      // researcher who offers it (many-many, via researcher_research_area).
      sql.append("AND r.researcher_id IN "
               + "(SELECT rra.researcher_id FROM researcher_research_area rra WHERE rra.area_id = ?) ");
      params.add(Integer.parseInt(areaId));
    }
    if (fundedOnly) {
      sql.append("AND o.funding_available = 1 ");
    }
    // Soonest deadline first; positions with no deadline go last
    sql.append("ORDER BY o.application_deadline IS NULL, o.application_deadline, o.title");

    PreparedStatement ps = con.prepareStatement(sql.toString());
    for (int i = 0; i < params.size(); i++) {
      ps.setObject(i + 1, params.get(i));
    }
    ResultSet rs = ps.executeQuery();

    while (rs.next()) {
      Map<String, Object> row = new HashMap<>();
      row.put("id", rs.getInt("opportunity_id"));
      row.put("title", rs.getString("title"));
      row.put("type", rs.getString("opportunity_type"));
      row.put("funded", rs.getInt("funding_available") == 1);
      row.put("start", rs.getString("expected_start_term"));         // can be NULL
      row.put("deadline", rs.getString("application_deadline"));     // can be NULL
      row.put("researcherId", rs.getInt("researcher_id"));
      row.put("researcher", rs.getString("first_name") + " " + rs.getString("last_name"));
      row.put("department", rs.getString("department_name"));
      row.put("university", rs.getString("university_name"));

      // Short preview of the description (can be NULL)
      String desc = rs.getString("description");
      if (desc != null && desc.length() > 160) {
        desc = desc.substring(0, 160).trim() + "...";
      }
      row.put("preview", desc);

      opportunities.add(row);
    }
  } catch (Exception e) {
    error = e.getMessage();
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <h1>Find opportunities</h1>
    <p class="sub">Browse open research positions by keyword, type, university, or research area.</p>

    <div class="search-layout">
      <form class="filters" action="opportunities.jsp" method="get">
        <div class="field">
          <label for="q">Keyword</label>
          <input type="text" id="q" name="q" value="<%= esc(keyword) %>" placeholder="e.g. machine learning">
        </div>
        <div class="field">
          <label for="type">Type</label>
          <select id="type" name="type">
            <option value="">Any type</option>
            <% for (String t : types) { %>
              <option value="<%= esc(t) %>" <%= t.equals(type) ? "selected" : "" %>><%= esc(t) %></option>
            <% } %>
          </select>
        </div>
        <div class="field">
          <label for="area">Research area</label>
          <select id="area" name="area">
            <option value="">Any area</option>
            <% for (Map<String, Object> a : areas) { %>
              <option value="<%= a.get("id") %>" <%= a.get("id").equals(areaId) ? "selected" : "" %>><%= esc(a.get("name")) %></option>
            <% } %>
          </select>
        </div>
        <div class="field">
          <label for="university">University</label>
          <select id="university" name="university">
            <option value="">Any university</option>
            <% for (Map<String, Object> un : universities) { %>
              <option value="<%= un.get("id") %>" <%= un.get("id").equals(universityId) ? "selected" : "" %>><%= esc(un.get("name")) %></option>
            <% } %>
          </select>
        </div>
        <div class="field">
          <label class="check">
            <input type="checkbox" name="funded" value="1" <%= fundedOnly ? "checked" : "" %>>
            Only funded positions
          </label>
        </div>
        <button type="submit" class="btn btn-primary">Search</button>
        <a class="reset" href="opportunities.jsp">Clear filters</a>
      </form>

      <div class="results">
        <% if (error != null) { %>
          <p class="empty">Database error: <%= esc(error) %></p>
        <% } else if (opportunities.isEmpty()) { %>
          <p class="empty">No open opportunities match your search. Try removing a filter.</p>
        <% } else { %>
          <p class="result-count"><%= opportunities.size() %> opportunit<%= opportunities.size() == 1 ? "y" : "ies" %> found</p>

          <%-- A div (not an <a>) so we can have two separate links inside: the position and the researcher --%>
          <% for (Map<String, Object> o : opportunities) {
               boolean funded = (Boolean) o.get("funded"); %>
            <div class="result">
              <div class="result-top">
                <a class="result-title" href="opportunity.jsp?id=<%= o.get("id") %>"><%= esc(o.get("title")) %></a>
                <span class="badge <%= funded ? "badge-yes" : "" %>"><%= funded ? "Funded" : "Unfunded" %></span>
              </div>
              <p class="result-meta">
                <%= esc(o.get("type")) %>
                <%= o.get("start") == null ? "" : " &middot; Starts " + esc(o.get("start")) %>
                <%= o.get("deadline") == null ? "" : " &middot; Apply by " + esc(o.get("deadline")) %>
              </p>
              <p class="result-meta">
                <a href="researcher.jsp?id=<%= o.get("researcherId") %>"><%= esc(o.get("researcher")) %></a>
                &middot; <%= esc(o.get("department")) %>, <%= esc(o.get("university")) %>
              </p>
              <% if (o.get("preview") != null) { %>
                <p class="result-meta"><%= esc(o.get("preview")) %></p>
              <% } %>
            </div>
          <% } %>
        <% } %>
      </div>
    </div>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
