<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ include file="includes/db.jspf" %>
<%@ include file="includes/auth.jspf" %>
<%
  String pageTitle = "Create account | ResearchMatch";
  String error = null;
  String fullName = "";
  String email = "";
  String role = "";

  // go to dashbord if logged in
  if (session.getAttribute("userId") != null) {
    response.sendRedirect(request.getContextPath() + "/dashboard.jsp");
    return;
  }

  if ("POST".equalsIgnoreCase(request.getMethod())) {
    request.setCharacterEncoding("UTF-8"); 
    fullName = request.getParameter("name") == null ? "" : request.getParameter("name").trim();
    email    = request.getParameter("email") == null ? "" : request.getParameter("email").trim().toLowerCase();
    String password = request.getParameter("password");
    role     = request.getParameter("role") == null ? "" : request.getParameter("role");

    // validate input
    if (fullName.isEmpty()) {
      error = "Please enter your name.";
    } else if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) {
      error = "Please enter a valid email address.";
    } else if (password == null || password.length() < 8) {
      error = "Password must be at least 8 characters.";
    } else if (!role.equals("student") && !role.equals("researcher")) {
      error = "Please choose Student or Researcher.";
    } else {
      
      int sp = fullName.indexOf(' ');
      String firstName = sp < 0 ? fullName : fullName.substring(0, sp);
      String lastName  = sp < 0 ? ""       : fullName.substring(sp + 1).trim();

      try (Connection con = getConnection(application)) {
        PreparedStatement check = con.prepareStatement("SELECT 1 FROM users WHERE email = ?");
        check.setString(1, email);
        ResultSet rs = check.executeQuery();
        if (rs.next()) {
          error = "An account with that email already exists.";
        } else {
          PreparedStatement ins = con.prepareStatement(
              "INSERT INTO users (first_name, last_name, email, password_hash, role, created_at) "
            + "VALUES (?, ?, ?, ?, ?, NOW())");
          ins.setString(1, firstName);
          ins.setString(2, lastName);
          ins.setString(3, email);
          ins.setString(4, hashPassword(password));
          ins.setString(5, role);
          ins.executeUpdate();

          response.sendRedirect(request.getContextPath() + "/login.jsp?registered=1");
          return;
        }
      } catch (SQLIntegrityConstraintViolationException e) {
        error = "An account with that email already exists."; 
      } catch (Exception e) {
        application.log("Registration failed", e);
        error = "Something went wrong creating your account. Please try again.";
      }
    }
  }
%>
<%@ include file="includes/header.jspf" %>

<section class="auth">
  <div class="auth-box">
    <h1>Create account</h1>
    <p class="sub">Set up your profile to start exploring</p>

    <% if (error != null) { %>
      <p class="form-error" role="alert" style="color:#b00020;margin:0 0 1rem;"><%= esc(error) %></p>
    <% } %>

    <form action="${pageContext.request.contextPath}/register.jsp" method="post">
      <div class="field">
        <label for="name">Full name</label>
        <input type="text" id="name" name="name" autocomplete="name" value="<%= esc(fullName) %>" required>
      </div>
      <div class="field">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" autocomplete="email" value="<%= esc(email) %>" required>
      </div>
      <div class="field">
        <label for="password">Password</label>
        <input type="password" id="password" name="password" autocomplete="new-password" minlength="8" required>
        <span class="hint">Use at least 8 characters.</span>
      </div>

      <div class="field">
        <label>I am a...</label>

        <div class="role-options">
          <label>
            <input type="radio" name="role" value="student" <%= role.equals("student") ? "checked" : "" %> required>
            Student
          </label>

          <label>
            <input type="radio" name="role" value="researcher" <%= role.equals("researcher") ? "checked" : "" %> required>
            Researcher
          </label>
        </div>
      </div>

      <button type="submit" class="btn btn-primary">Create account</button>
    </form>

    <p class="auth-switch">
      Already have an account? <a href="${pageContext.request.contextPath}/login.jsp">Log in</a>
    </p>
  </div>
</section>

<%@ include file="includes/footer.jspf" %>
