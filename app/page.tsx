import { createClient } from "@/utils/supabase/client";

export default async function Home() {
  const supabase = createClient();
  const { data: test } = await supabase.from("test").select("test");
  console.log("test: ", test);

  if (!test) return <>Something bad happened while connection</>;

  return (
    <main className="bg-red-400">
      I SEE THIS here comes from db: <span className="bg-green-400">{test[0].test}</span>
    </main>
  );
}
