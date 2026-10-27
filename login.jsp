<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%@ include file="includes/auth.jspf" %>
<%
  String pageTitle = "Log in | ResearchMatch";
  String error = null;
  String email = "";

  // go to dashbord if logged in
  if (session.getAttribute("userId") != null) {
    response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
    return;
  }

  if ("POST".equalsIgnoreCase(request.getMethod())) {
    request.setCharacterEncoding("UTF-8");
    email = request.getParameter("email") == null ? "" : request.getParameter("email").trim().toLowerCase();
    String password = request.getParameter("password") == null ? "" : request.getParameter("password");

    try (Connection con = getConnection(application)) {
      PreparedStatement ps = con.prepareStatement(
          "SELECT user_id, first_name, last_name, password_hash, role FROM users WHERE email = ?");
      ps.setString(1, email);
      ResultSet rs = ps.executeQuery();

      if (rs.next() && verifyPassword(password, rs.getString("password_hash"))) {
        int userId = rs.getInt("user_id");
        String firstName = rs.getString("first_name");
        String lastName = rs.getString("last_name");
        String role = rs.getString("role");

        session.invalidate();
        HttpSession newSession = request.getSession(true);
        newSession.setAttribute("userId", userId);
        newSession.setAttribute("userName", (firstName + " " + (lastName == null ? "" : lastName)).trim());
        newSession.setAttribute("userFirstName", firstName);
        newSession.setAttribute("userRole", role);

        response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
        return;
      } else {
        error = "Invalid email or password.";
      }
    } catch (Exception e) {
      application.log("Login failed", e);
      error = "Something went wrong. Please try again.";
    }
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="auth">
  <div class="auth-box">
    <h1>Log in</h1>
    <p class="sub">Welcome back.</p>

    <% if (request.getParameter("registered") != null && error == null) { %>
      <p class="form-success" style="color:#1b6e3c;margin:0 0 1rem;">Account created. Please log in.</p>
    <% } %>
    <% if (error != null) { %>
      <p class="form-error" role="alert" style="color:#b00020;margin:0 0 1rem;"><%= esc(error) %></p>
    <% } %>

    <form action="${pageContext.request.contextPath}/login.jsp" method="post">

      <div class="field">
        <label for="email">Email</label>
        <input
          type="email"
          id="email"
          name="email"
          autocomplete="email"
          value="<%= esc(email) %>"
          required
        >
      </div>

      <div class="field">
        <label for="password">Password</label>
        <input
          type="password"
          id="password"
          name="password"
          autocomplete="current-password"
          required
        >
      </div>

      <button type="submit" class="btn btn-primary">Log in</button>
    </form>

    <p class="auth-switch">
      New here?
      <a href="${pageContext.request.contextPath}/register.jsp">
        Create an account
      </a>
    </p>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>