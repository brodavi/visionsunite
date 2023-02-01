defmodule VisionsUnite.Email do
  import Swoosh.Email
  alias VisionsUnite.Accounts

  def seeking_group_vetting(user, group) do
    new()
    |> from({"Visions Unite", "voice@visionsunite.org"})
    |> to({"Friend", user.email})
    |> subject("[Visions Unite] Your assistance is requested! (Group Vetting)")
    |> text_body("""
      Someone has proposed the following group:

      Title: #{group.title}

      Description: #{group.body}

      Visions Unite depends on members like you to help bring the most relevant and important messages to the Visions Unite community. So if you feel this group should exist on the site, please vet this group. Likewise if you do not think this group is likely to produce relevant and important messages, please reject this group.

      At your convenience, please log into: https://visionsunite.gigalixirapp.com/ and make your voice heard.

      The Visions Unite community appreciates your efforts!

      In Solidarity,

      Your Friends at Visions Unite
      https://visionsunite.gigalixirapp.com/
      """)
  end

  def seeking_message_support(user, message, group) do
    new()
    |> from({"Visions Unite", "voice@visionsunite.org"})
    |> to({"Friend", user.email})
    |> subject("[Visions Unite] Your assistance is requested! (Message Support)")
    |> text_body("""
      Someone has proposed the following message:

      Title: #{message.title}

      Body: #{message.body}

      Visions Unite depends on members like you to help bring the most relevant and important messages to the Visions Unite community. So if you feel this message should be seen by everyone in the group: "#{group.title}", please support this message. Likewise if you do not think this message is relevant or important to the group: "#{group.title}", please reject this message.

      At your convenience, please log into: https://visionsunite.gigalixirapp.com/ and make your voice heard.

      Your community at group: "#{group.title}" and all of Visions Unite appreciates your consideration!

      In Solidarity,

      Your Friends at Visions Unite
      https://visionsunite.gigalixirapp.com/
      """)
  end
end
