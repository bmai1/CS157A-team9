<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%
  String pageTitle = "Researcher | ResearchMatch";
  String error = null;

  // 1. Which researcher? The search page links here as researcher.jsp?id=11
  int researcherId = -1;                     // -1 matches nobody
  try {
    researcherId = Integer.parseInt(request.getParameter("id"));
  } catch (NumberFormatException e) {
    // the id is missing or not a number: keep -1, so the page says "not found"
  }
  
  List<String> areas = new ArrayList<>();    // this researcher's research areas
  List<Map<String, Object>> publications = new ArrayList<>();   // this researcher's papers

  Map<String, Object> profile = null;        // stays null if no researcher has this id

  try (Connection con = getConnection(application)) {
    // 2. One row with everything about this researcher. These are theta joins
    //    (R JOIN S ON <condition>) on the foreign keys from the E/R diagram.
    PreparedStatement ps = con.prepareStatement(
        "SELECT u.first_name, u.last_name, r.academic_title, r.contact_email, r.website, "
      + "       r.biography, r.accepting_phd, r.lab_id, d.name AS department_name, "
      + "       un.name AS university_name, un.city, un.state, un.country "
      + "FROM researcher r "
      + "JOIN users u       ON u.user_id = r.researcher_id "
      + "JOIN department d  ON d.department_id = r.department_id "
      + "JOIN university un ON un.university_id = d.university_id "
      + "WHERE r.researcher_id = ?");
    ps.setInt(1, researcherId);
    ResultSet rs = ps.executeQuery();

    // researcher_id is the primary key, so there is at most one row: "if", not "while"
    if (rs.next()) {
      profile = new HashMap<>();
      profile.put("name", rs.getString("first_name") + " " + rs.getString("last_name"));
      profile.put("title", rs.getString("academic_title"));          // can be NULL
      profile.put("department", rs.getString("department_name"));
      profile.put("university", rs.getString("university_name"));
      profile.put("location", rs.getString("city") + ", " + rs.getString("state") + ", " + rs.getString("country"));
      profile.put("email", rs.getString("contact_email"));
      profile.put("website", rs.getString("website"));
      profile.put("bio", rs.getString("biography"));
      profile.put("phd", rs.getInt("accepting_phd") == 1);
      profile.put("lab", null);                                      // filled in below if they have one
      pageTitle = profile.get("name") + " | ResearchMatch";

      // 3. The lab. Member Of is "at most one", so lab_id can be NULL (no lab).
      //    Joining lab above would drop researchers without a lab, so instead we
      //    look the lab up with a second small query, only when there is one.
      Object labId = rs.getObject("lab_id");                         // null when there is no lab
      if (labId != null) {
        PreparedStatement labPs = con.prepareStatement("SELECT name FROM lab WHERE lab_id = ?");
        labPs.setObject(1, labId);
        ResultSet labRs = labPs.executeQuery();
        if (labRs.next()) {
          profile.put("lab", labRs.getString("name"));
        }
      }

      // 4. Research areas. Studies is many-many, so the areas are in the junction table
      //    researcher_research_area; a theta join to research_area gives their names.
      PreparedStatement areaPs = con.prepareStatement(
          "SELECT ra.name "
        + "FROM researcher_research_area rra "
        + "JOIN research_area ra ON ra.area_id = rra.area_id "
        + "WHERE rra.researcher_id = ? "
        + "ORDER BY ra.name");
      areaPs.setInt(1, researcherId);
      ResultSet areaRs = areaPs.executeQuery();
      while (areaRs.next()) {                                        // a researcher can have many areas
        areas.add(areaRs.getString("name"));
      } 

      // 5. Publications. Writes is many-many: the junction table researcher_publication
      //    says which researcher wrote which paper. Newest papers first.
      PreparedStatement pubPs = con.prepareStatement(
          "SELECT p.publication_id, p.title, p.publication_year, p.venue, p.publication_url "
        + "FROM publication p "
        + "JOIN researcher_publication rp ON rp.publication_id = p.publication_id "
        + "WHERE rp.researcher_id = ? "
        + "ORDER BY p.publication_year DESC, p.title");
      pubPs.setInt(1, researcherId);
      ResultSet pubRs = pubPs.executeQuery();

      // Two more queries, prepared once and run once per paper with a different ?:
      //   - the paper's research topics (publication_research_area, also many-many)
      //   - the paper's other authors (the same junction table, minus this researcher)
      PreparedStatement topicPs = con.prepareStatement(
          "SELECT ra.name "
        + "FROM publication_research_area pra "
        + "JOIN research_area ra ON ra.area_id = pra.area_id "
        + "WHERE pra.publication_id = ? "
        + "ORDER BY ra.name");
      PreparedStatement coauthorPs = con.prepareStatement(
          "SELECT rp.researcher_id, u.first_name, u.last_name "
        + "FROM researcher_publication rp "
        + "JOIN users u ON u.user_id = rp.researcher_id "
        + "WHERE rp.publication_id = ? AND rp.researcher_id <> ? "
        + "ORDER BY u.last_name");

      while (pubRs.next()) {
        int publicationId = pubRs.getInt("publication_id");
        Map<String, Object> pub = new HashMap<>();
        pub.put("title", pubRs.getString("title"));
        pub.put("year", pubRs.getString("publication_year"));
        pub.put("venue", pubRs.getString("venue"));                 // can be NULL
        pub.put("url", pubRs.getString("publication_url"));          // can be NULL

        List<String> topics = new ArrayList<>();
        topicPs.setInt(1, publicationId);
        ResultSet topicRs = topicPs.executeQuery();
        while (topicRs.next()) {
          topics.add(topicRs.getString("name"));
        }
        pub.put("topics", topics);

        List<Map<String, Object>> coauthors = new ArrayList<>();
        coauthorPs.setInt(1, publicationId);
        coauthorPs.setInt(2, researcherId);                           // leave out this researcher
        ResultSet coRs = coauthorPs.executeQuery();
        while (coRs.next()) {
          Map<String, Object> co = new HashMap<>();
          co.put("id", coRs.getInt("researcher_id"));
          co.put("name", coRs.getString("first_name") + " " + coRs.getString("last_name"));
          coauthors.add(co);
        }
        pub.put("coauthors", coauthors);

        publications.add(pub);
      }
    }
  } catch (Exception e) {
    error = e.getMessage();
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="page">
  <div class="container">
    <a class="back-link" href="researchers.jsp">&larr; Back to search</a>

    <% if (error != null) { %>
      <p class="empty">Database error: <%= esc(error) %></p>
    <% } else if (profile == null) { %>
      <p class="empty">We couldn't find that researcher.</p>
    <% } else {
         boolean phd = (Boolean) profile.get("phd");
         String website = (String) profile.get("website"); %>

      <!-- Name, title, and PhD status -->
      <div class="profile-head">
        <div>
          <h1><%= esc(profile.get("name")) %></h1>
          <p class="sub">
            <%= profile.get("title") == null ? "" : esc(profile.get("title")) + " &middot; " %><%= esc(profile.get("department")) %>
          </p>
        </div>
        <span class="badge <%= phd ? "badge-yes" : "" %>">
          <%= phd ? "Accepting PhD students" : "Not accepting PhD students" %>
        </span>
      </div>

      <!-- Details -->
      <div class="card">
        <h2>About</h2>
        <dl class="facts">
          <dt>University</dt>
          <dd><%= esc(profile.get("university")) %> (<%= esc(profile.get("location")) %>)</dd>

          <dt>Department</dt>
          <dd><%= esc(profile.get("department")) %></dd>

          <dt>Research lab</dt>
          <dd><%= profile.get("lab") == null ? "Not part of a lab" : esc(profile.get("lab")) %></dd>
          
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

          <dt>Contact</dt>
          <dd>
            <% if (profile.get("email") == null) { %>
              No contact email listed
            <% } else { %>
              <a href="mailto:<%= esc(profile.get("email")) %>"><%= esc(profile.get("email")) %></a>
            <% } %>
          </dd>

          <%-- Only show the website as a link if it is a normal web address --%>
          <% if (website != null && website.startsWith("http")) { %>
            <dt>Website</dt>
            <dd><a href="<%= esc(website) %>" target="_blank"><%= esc(website) %></a></dd>
          <% } %>
        </dl>

        <% if (profile.get("bio") != null) { %>
          <h2 class="card-subhead">Biography</h2>
          <p><%= esc(profile.get("bio")) %></p>
        <% } %>
      </div>
      
      <!-- Publications -->
      <div class="card">
        <h2>Publications</h2>
        <% if (publications.isEmpty()) { %>
          <p>No publications listed yet.</p>
        <% } else { %>
          <ul class="plain-list">
            <% for (Map<String, Object> pub : publications) {
                 String url = (String) pub.get("url");
                 List<String> topics = (List<String>) pub.get("topics");
                 List<Map<String, Object>> coauthors = (List<Map<String, Object>>) pub.get("coauthors"); %>
              <li>
                <%-- The title links to the paper only if the link is a normal web address --%>
                <% if (url != null && url.startsWith("http")) { %>
                  <a class="item-title" href="<%= esc(url) %>" target="_blank"><%= esc(pub.get("title")) %></a>
                <% } else { %>
                  <p class="item-title"><%= esc(pub.get("title")) %></p>
                <% } %>

                <p class="item-meta">
                  <%= esc(pub.get("year")) %><%= pub.get("venue") == null ? "" : " &middot; " + esc(pub.get("venue")) %>
                  <%= topics.isEmpty() ? "" : " &middot; Topics: " + esc(String.join(", ", topics)) %>
                </p>

                <% if (!coauthors.isEmpty()) { %>
                  <p class="item-meta">With
                    <% for (int i = 0; i < coauthors.size(); i++) {
                         Map<String, Object> co = coauthors.get(i); %><%= i > 0 ? ", " : "" %><a href="researcher.jsp?id=<%= co.get("id") %>"><%= esc(co.get("name")) %></a><% } %>
                  </p>
                <% } %>
              </li>
            <% } %>
          </ul>
        <% } %>
      </div>
    <% } %>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>