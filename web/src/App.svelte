<script>
  import Router from "svelte-spa-router";
  import Homepage from "./routes/homepage/Homepage.svelte";
  import NotFound from "./routes/NotFound.svelte";
  import RegistrationForm from "./routes/register_provider/RegistrationForm.svelte";
  import AdminRouter from "./routes/admin/AdminRouter.svelte";
  import ProviderLogin from "./routes/provider/ProviderLogin.svelte";

  const routes = {
    "/": Homepage,
    "/register_provider": RegistrationForm,

    "/admin": AdminRouter,
    "/admin/*": AdminRouter,
    "/provider": ProviderLogin,
    "*": NotFound,
  }
</script>

<Router {routes} />
